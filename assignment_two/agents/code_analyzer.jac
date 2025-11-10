
# agents/CodeAnalyzer.jac
include agent_core;

# CCG node types for relationship tracking
node Module { 
    has name: str; 
    has file_path: str;
    has imports: list[str] = [];
}
node Function { 
    has name: str; 
    has file_path: str;
    has parameters: str = "";
    has docstring: str = "";
    has calls: list[str] = [];  # Functions this function calls
    has called_by: list[str] = [];  # Functions that call this
}
node Class { 
    has name: str; 
    has file_path: str;
    has docstring: str = "";
    has inherits_from: list[str] = [];  # Parent classes
    has methods: list[str] = [];  # Method names
}
node GraphRoot { has name: str = "ccg_root"; }

node CodeAnalyzer(Toolbox) {
    has parsed_results: dict[str, dict] = {};
    has ccg_root: GraphRoot = None;
    has file_list: list[str] = [];

    def parse_file_with_treesitter(filepath: str) -> dict;
    def build_code_context_graph(file_list: list[str]) -> GraphRoot;
    def extract_functions_regex(source_code: str, language: str) -> list[dict];
    def extract_classes_regex(source_code: str, language: str) -> list[dict];
    def detect_language(filepath: str) -> str;
    def extract_function_calls(source_code: str, language: str) -> dict[str, list[str]];
    def build_relationships() -> None;
    def get_callers(func_name: str) -> list[str];
    def get_callees(func_name: str) -> list[str];
    def find_function_in_ccg(func_name: str) -> Function;

    def analyze_codebase(file_list: list[str]) -> str by llm(
        method="ReAct",
        tools=[self.build_code_context_graph, self.get_callers, self.get_callees]
    );

    impl CodeAnalyzer.process -> None {
        _ = self.analyze_codebase(visitor.file_list);
    }

    impl CodeAnalyzer.parse_file_with_treesitter {
        try {
            with open(filepath, "r", encoding="utf-8") as f {
                source_code = f.read();
            }
            
            language = self.detect_language(filepath);
            functions = self.extract_functions_regex(source_code, language);
            classes = self.extract_classes_regex(source_code, language);
            
            parsed_data = {
                "language": language,
                "functions": functions,
                "classes": classes
            };
            
            self.parsed_results[filepath] = parsed_data;
            return parsed_data;
            
        } except Exception as e {
            return {"error": f"Failed to parse {filepath}"};
        }
    }

    impl CodeAnalyzer.build_code_context_graph {
        self.ccg_root = root ++> GraphRoot();
        
        # First pass: Create nodes
        for filepath in file_list {
            parsed_data = self.parse_file_with_treesitter(filepath);
            
            if "error" not in parsed_data {
                # Create module node
                mod_name = filepath.split("/")[-1].replace(".py", "").replace(".js", "");
                module_node = self.ccg_root ++> Module(name=mod_name, file_path=filepath);
                
                # Create function nodes
                for func_data in parsed_data.get("functions", []) {
                    func_node = module_node ++> Function(
                        name=func_data["name"],
                        file_path=filepath,
                        parameters=func_data.get("parameters", ""),
                        docstring=func_data.get("docstring", "")
                    );
                }
                
                # Create class nodes
                for class_data in parsed_data.get("classes", []) {
                    class_node = module_node ++> Class(
                        name=class_data["name"],
                        file_path=filepath,
                        docstring=class_data.get("docstring", "")
                    );
                }
            }
        }
        
        # Second pass: Build relationships
        self.build_relationships();
        
        return self.ccg_root;
    }
    
    impl CodeAnalyzer.build_relationships {
        # Build call graph relationships
        all_modules = [self.ccg_root -->];
        
        for module in all_modules {
            if type(module).__name__ == "Module" {
                try {
                    with open(module.file_path, "r", encoding="utf-8") as f {
                        source_code = f.read();
                    }
                    
                    language = self.detect_language(module.file_path);
                    call_map = self.extract_function_calls(source_code, language);
                    
                    # Update function nodes with relationships
                    functions = [module -->];
                    for func in functions {
                        if type(func).__name__ == "Function" {
                            func.calls = call_map.get(func.name, []);
                            
                            # Update called_by relationships
                            for called_func in func.calls {
                                target_func = self.find_function_in_ccg(called_func);
                                if target_func and func.name not in target_func.called_by {
                                    target_func.called_by.append(func.name);
                                }
                            }
                        }
                    }
                } except Exception {
                    continue;
                }
            }
        }
    }
    
    impl CodeAnalyzer.extract_function_calls {
        call_map = {};
        lines = source_code.split("\n");
        current_func = "";
        
        for (i, line) in enumerate(lines) {
            stripped = line.strip();
            
            # Track current function context
            if language == "python" and stripped.startswith("def ") and "(" in stripped {
                current_func = stripped.split("def ")[1].split("(")[0].strip();
                call_map[current_func] = [];
            }
            
            # Find function calls in current line
            if current_func and language == "python" {
                # Simple regex for function_name() patterns
                words = stripped.split();
                for word in words {
                    if "(" in word and not word.startswith("def") {
                        func_call = word.split("(")[0].strip();
                        if func_call and func_call != current_func and func_call.isidentifier() {
                            if func_call not in call_map[current_func] {
                                call_map[current_func].append(func_call);
                            }
                        }
                    }
                }
            }
        }
        
        return call_map;
    }
    
    impl CodeAnalyzer.get_callers {
        callers = [];
        all_modules = [self.ccg_root -->];
        
        for module in all_modules {
            if type(module).__name__ == "Module" {
                functions = [module -->];
                for func in functions {
                    if type(func).__name__ == "Function" {
                        if func_name in func.calls {
                            callers.append(func.name);
                        }
                    }
                }
            }
        }
        
        return callers;
    }
    
    impl CodeAnalyzer.get_callees {
        target_func = self.find_function_in_ccg(func_name);
        if target_func {
            return target_func.calls;
        }
        return [];
    }
    
    impl CodeAnalyzer.find_function_in_ccg {
        all_modules = [self.ccg_root -->];
        
        for module in all_modules {
            if type(module).__name__ == "Module" {
                functions = [module -->];
                for func in functions {
                    if type(func).__name__ == "Function" and func.name == func_name {
                        return func;
                    }
                }
            }
        }
        
        return None;
    }
    
    impl CodeAnalyzer.extract_functions_regex {
        functions = [];
        lines = source_code.split("\n");
        
        for (i, line) in enumerate(lines) {
            stripped = line.strip();
            
            if language == "python" and stripped.startswith("def ") and "(" in stripped {
                func_name = stripped.split("def ")[1].split("(")[0].strip();
                params = stripped.split("(")[1].split(")")[0] if ")" in stripped else "";
                
                functions.append({
                    "name": func_name,
                    "parameters": params,
                    "line": i + 1
                });
            } elif language == "javascript" and "function " in stripped {
                if stripped.startswith("function ") {
                    func_name = stripped.split("function ")[1].split("(")[0].strip();
                    functions.append({
                        "name": func_name,
                        "line": i + 1
                    });
                }
            }
        }
        
        return functions;
    }
    
    impl CodeAnalyzer.extract_classes_regex {
        classes = [];
        lines = source_code.split("\n");
        
        for (i, line) in enumerate(lines) {
            stripped = line.strip();
            
            if language == "python" and stripped.startswith("class ") and ":" in stripped {
                class_name = stripped.split("class ")[1].split("(")[0].split(":")[0].strip();
                classes.append({
                    "name": class_name,
                    "line": i + 1
                });
            } elif language == "javascript" and stripped.startswith("class ") {
                class_name = stripped.split("class ")[1].split(" ")[0].strip();
                classes.append({
                    "name": class_name,
                    "line": i + 1
                });
            }
        }
        
        return classes;
    }
    
    impl CodeAnalyzer.detect_language {
        if filepath.endswith(".py") {
            return "python";
        } elif filepath.endswith(".js") or filepath.endswith(".jsx") {
            return "javascript";
        } elif filepath.endswith(".go") {
            return "go";
        }
        return "unknown";
    }
}
sem CodeAnalyzer.analyze_codebase = """
    Build a Code Context Graph (CCG) from the file list.
    1. Call build_code_context_graph first.
    2. Only call get_callers if explicitly asked about function callers.
    Return: 'Code analysis complete.'
    """;