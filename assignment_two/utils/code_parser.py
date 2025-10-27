# utils/code_parser.py
import os
import re
import ast

def parse_file(file_path: str) -> dict:
    """Parse file and return structured code components."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        source_code = f.read()
    
    ext = os.path.splitext(file_path)[1].lower()
    
    if ext == '.py':
        return _parse_python(source_code)
    elif ext == '.jac':
        return _parse_jac_fallback(source_code)
    else:
        return {"functions": [], "classes": [], "variables": [], "calls": []}


def _parse_python(source_code: str) -> dict:
    """
    Parse Python code using ast to extract:
    - functions (sync/async)
    - classes (with inheritance)
    - top-level variables
    - function calls
    """
    try:
        tree = ast.parse(source_code)
    except SyntaxError:
        return {"functions": [], "classes": [], "variables": [], "calls": []}

    functions = []
    classes = []
    variables = []
    calls = []

    for node in ast.walk(tree):
        # Top-level variable assignments (e.g., x = 10)
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name):
                    variables.append({
                        "name": target.id,
                        "lineno": node.lineno
                    })

        # Function definitions
        elif isinstance(node, ast.FunctionDef):
            functions.append({
                "name": node.name,
                "lineno": node.lineno,
                "docstring": ast.get_docstring(node) or "",
                "async": False
            })
        elif isinstance(node, ast.AsyncFunctionDef):
            functions.append({
                "name": node.name,
                "lineno": node.lineno,
                "docstring": ast.get_docstring(node) or "",
                "async": True
            })

        # Class definitions with inheritance
        elif isinstance(node, ast.ClassDef):
            bases = []
            for base in node.bases:
                if isinstance(base, ast.Name):
                    bases.append(base.id)
                # Handle attr (e.g., BaseClass.Sub) if needed
            classes.append({
                "name": node.name,
                "lineno": node.lineno,
                "docstring": ast.get_docstring(node) or "",
                "bases": bases
            })

        # Function calls
        elif isinstance(node, ast.Call):
            if isinstance(node.func, ast.Name):
                calls.append({
                    "callee": node.func.id,
                    "lineno": node.lineno
                })

    return {
        "functions": functions,
        "classes": classes,
        "variables": variables,
        "calls": calls
    }


def _parse_jac_fallback(code: str) -> dict:
    """Basic Jac parsing using regex."""
    functions = []
    classes = []
    
    # Match walker/ability definitions
    func_pattern = r'(walker|ability)\s+(\w+)\s*{'
    for match in re.finditer(func_pattern, code):
        functions.append({
            "name": match.group(2),
            "signature": f"{match.group(1)} {match.group(2)}",
            "docstring": "",
            "calls": []
        })
    
    # Match node definitions
    node_pattern = r'node\s+(\w+)\s*{'
    for match in re.finditer(node_pattern, code):
        classes.append({
            "name": match.group(1),
            "bases": [],
            "methods": []
        })
    
    return {
        "functions": functions,
        "classes": classes,
        "variables": [],
        "calls": []
    }