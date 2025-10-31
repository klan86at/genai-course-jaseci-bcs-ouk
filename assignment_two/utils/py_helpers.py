# utils/py_utils.py
import os
import shutil
import tempfile
from pathlib import Path
from urllib.parse import urlparse
from typing import Dict, List, Any, Optional

import pygit2
from jaseci.jsorc.live_actions import jaseci_action

# Lazy-load Tree-sitter to avoid import errors if not built
try:
    from tree_sitter import Language, Parser
    TREE_SITTER_AVAILABLE = True
    # These must be built first (see setup instructions)
    PY_LANG = Language("build/my-languages.so", "python")
    JAC_LANG = Language("build/my-languages.so", "jac")
except (ImportError, OSError):
    TREE_SITTER_AVAILABLE = False
    PY_LANG = None
    JAC_LANG = None

# ======================
# 1. REPO CLONING
# ======================

@jaseci_action(act_group=["PyUtils"], allow_remote=True)
def clone_repository(github_url: str) -> Dict[str, Any]:
    """Clone a public GitHub repo. Returns {'success': bool, 'repo_path'?: str, 'error'?: str}"""
    try:
        if not github_url or not isinstance(github_url, str):
            return {"success": False, "error": "Invalid input: GitHub URL must be a non-empty string."}

        parsed = urlparse(github_url)
        if parsed.netloc != "github.com":
            return {"success": False, "error": "URL must be from github.com (e.g., https://github.com/owner/repo)."}

        path_parts = [p for p in parsed.path.strip("/").split("/") if p]
        if len(path_parts) < 2:
            return {"success": False, "error": "Invalid GitHub URL format. Expected: https://github.com/owner/repo"}

        repo_name = path_parts[-1].replace(".git", "")
        if not repo_name:
            return {"success": False, "error": "Could not extract repository name."}

        base_temp = "/tmp/codebase_genius"
        os.makedirs(base_temp, exist_ok=True)
        clone_path = os.path.join(base_temp, repo_name)

        if os.path.exists(clone_path):
            shutil.rmtree(clone_path)

        pygit2.clone_repository(github_url, clone_path)
        return {"success": True, "repo_path": clone_path}

    except pygit2.GitError as e:
        msg = str(e).lower()
        if "not found" in msg or "404" in msg:
            return {"success": False, "error": "Repository not found. Ensure the URL is correct and the repo is public."}
        elif "authentication" in msg or "403" in msg:
            return {"success": False, "error": "Access denied. Private repositories are not supported."}
        else:
            return {"success": False, "error": f"Git clone failed: {str(e)}"}
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


# ======================
# 2. FILE TREE & README
# ======================

@jaseci_action(act_group=["PyUtils"], allow_remote=True)
def generate_file_tree(repo_path: str) -> Dict[str, Any]:
    """Return nested dict of files, excluding ignored dirs."""
    if not os.path.exists(repo_path):
        return {"success": False, "error": "Repository path does not exist."}

    def walk(p: Path) -> Dict[str, Any]:
        tree = {}
        try:
            for item in sorted(p.iterdir()):
                name = item.name
                if name in {".git", "node_modules", "__pycache__", ".venv", "venv", ".pytest_cache", "build", "dist"}:
                    continue
                rel = str(item.relative_to(repo_path))
                if item.is_dir():
                    tree[rel] = walk(item)
                else:
                    tree[rel] = None
        except PermissionError:
            pass
        return tree

    try:
        tree = walk(Path(repo_path))
        return {"success": True, "file_tree": tree}
    except Exception as e:
        return {"success": False, "error": f"File tree generation failed: {str(e)}"}


@jaseci_action(act_group=["PyUtils"], allow_remote=True)
def read_readme(repo_path: str) -> Dict[str, Any]:
    """Read README.md (case-insensitive)."""
    candidates = ["README.md", "Readme.md", "readme.md", "README", "readme"]
    for name in candidates:
        p = Path(repo_path) / name
        if p.exists():
            try:
                content = p.read_text(encoding="utf-8")
                return {"success": True, "content": content}
            except Exception as e:
                return {"success": False, "error": f"Failed to read README: {str(e)}"}
    return {"success": True, "content": ""}


# ======================
# 3. LANGUAGE & PARSING
# ======================

@jaseci_action(act_group=["PyUtils"], allow_remote=True)
def detect_language(file_path: str) -> str:
    """Detect language from file extension."""
    if file_path.endswith(".py"):
        return "python"
    if file_path.endswith(".jac"):
        return "jac"
    return "unknown"


@jaseci_action(act_group=["PyUtils"], allow_remote=True)
def parse_with_treesitter(file_path: str, lang: str) -> Dict[str, Any]:
    """
    Parse file with Tree-sitter. Returns CCG-compatible fragment:
    {
      "nodes": [{"id": "...", "type": "...", "name": "...", "file": "..."}, ...],
      "edges": [{"from": "...", "to": "...", "type": "..."}, ...]
    }
    """
    if not TREE_SITTER_AVAILABLE:
        return {
            "success": False,
            "error": "Tree-sitter not available. Run: python build_grammars.py"
        }

    try:
        with open(file_path, "rb") as f:
            source = f.read()

        parser = Parser()
        if lang == "python":
            parser.set_language(PY_LANG)
        elif lang == "jac":
            parser.set_language(JAC_LANG)
        else:
            return {"success": False, "error": f"Unsupported language: {lang}"}

        tree = parser.parse(source)
        nodes, edges = _extract_ccg_from_tree(tree.root_node, lang, file_path)
        return {"success": True, "nodes": nodes, "edges": edges}

    except Exception as e:
        return {"success": False, "error": f"Parse failed: {str(e)}"}


# ======================
# 4. TREE-SITTER EXTRACTORS
# ======================

def _extract_ccg_from_tree(root_node, lang: str, file_path: str):
    """Extract CCG nodes and edges from Tree-sitter AST."""
    nodes = []
    edges = []
    file_name = Path(file_path).name
    module_id = f"module:{file_name}@{file_path}"

    nodes.append({
        "id": module_id,
        "type": "code_module",
        "name": file_name,
        "file_path": file_path,
        "language": lang
    })

    if lang == "python":
        _walk_python(root_node, file_path, module_id, nodes, edges)
    elif lang == "jac":
        _walk_jac(root_node, file_path, module_id, nodes, edges)

    return nodes, edges


def _walk_python(node, file_path: str, parent_id: str, nodes: list, edges: list):
    """Recursively walk Python AST."""
    if node.type == "function_definition":
        name = _get_node_text(node.child_by_field_name("name"), file_path)
        func_id = f"func:{name}@{file_path}"
        nodes.append({
            "id": func_id,
            "type": "code_function",
            "name": name,
            "file_path": file_path
        })
        edges.append({"from": parent_id, "to": func_id, "type": "contains"})

        # Extract calls inside function
        _extract_calls_python(node, func_id, file_path, nodes, edges)

    elif node.type == "class_definition":
        name = _get_node_text(node.child_by_field_name("name"), file_path)
        class_id = f"class:{name}@{file_path}"
        nodes.append({
            "id": class_id,
            "type": "code_class",
            "name": name,
            "file_path": file_path
        })
        edges.append({"from": parent_id, "to": class_id, "type": "contains"})

        # Inheritance
        for base in node.children_by_field_name("base"):
            base_name = _get_node_text(base, file_path)
            base_id = f"class:{base_name}@{file_path}"  # simplified (assume same file)
            edges.append({"from": class_id, "to": base_id, "type": "inherits"})

    # Recurse
    for child in node.children:
        _walk_python(child, file_path, parent_id, nodes, edges)


def _walk_jac(node, file_path: str, parent_id: str, nodes: list, edges: list):
    """Recursively walk Jac AST."""
    if node.type == "walker_def":
        name = _get_node_text(node.child_by_field_name("name"), file_path)
        walker_id = f"walker:{name}@{file_path}"
        nodes.append({
            "id": walker_id,
            "type": "code_function",
            "name": name,
            "file_path": file_path
        })
        edges.append({"from": parent_id, "to": walker_id, "type": "contains"})

    elif node.type == "node_def":
        name = _get_node_text(node.child_by_field_name("name"), file_path)
        node_id = f"node:{name}@{file_path}"
        nodes.append({
            "id": node_id,
            "type": "code_class",
            "name": name,
            "file_path": file_path
        })
        edges.append({"from": parent_id, "to": node_id, "type": "contains"})

    # Recurse
    for child in node.children:
        _walk_jac(child, file_path, parent_id, nodes, edges)


def _extract_calls_python(node, caller_id: str, file_path: str, nodes: list, edges: list):
    """Extract function calls within a Python function."""
    if node.type == "call":
        func_node = node.child_by_field_name("function")
        if func_node and func_node.type == "identifier":
            callee_name = _get_node_text(func_node, file_path)
            callee_id = f"func:{callee_name}@{file_path}"  # simplified
            # Add callee node (may be duplicate, Jac will dedupe)
            nodes.append({
                "id": callee_id,
                "type": "code_function",
                "name": callee_name,
                "file_path": file_path
            })
            edges.append({"from": caller_id, "to": callee_id, "type": "calls"})
    else:
        for child in node.children:
            _extract_calls_python(child, caller_id, file_path, nodes, edges)


def _get_node_text(node, file_path: str) -> str:
    """Extract source text from Tree-sitter node."""
    if not node:
        return ""
    with open(file_path, "rb") as f:
        source = f.read()
    return source[node.start_byte:node.end_byte].decode("utf-8")


# ======================
# 5. OUTPUT WRITING
# ======================

@jaseci_action(act_group=["PyUtils"], allow_remote=True)
def write_file(path: str, content: str) -> Dict[str, Any]:
    """Write content to file."""
    try:
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        Path(path).write_text(content, encoding="utf-8")
        return {"success": True}
    except Exception as e:
        return {"success": False, "error": f"Write failed: {str(e)}"}