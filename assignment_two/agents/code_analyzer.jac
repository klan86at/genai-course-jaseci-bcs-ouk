# Analyze source files and build Code Context Graph (CCG)
include graphs.code_base_graph;
include utils.code_parser;

walker build_ccg {
    root {
        # Start from repo marked as 'mapped'
        repo_nodes = [here --> node::repo(status == "mapped")];
        if !repo_nodes {
            print("No mapped repo found.");
            report {"error": "Repo not mapped."};
            disengage;
        }
        visit repo_nodes[0];
    }

    repo {
        source_files = --> node::file(language in ["python", "jac"]);
        for f in source_files {
            ast_data = self.parse_file(f);
            if ast_data {
                self.create_ccg_nodes(f, ast_data);
                print("CCG built for: " + f.path);
            }
        }
        here.status = "analyzed";
        report {"status": "CCG construction complete"};
    }

    ability parse_file(file_node) {
        repo_nodes = --> node::repo;
        full_path = py::os.path.join(repo_nodes[0].local_path, file_node.path);
        try {
            return py::code_parser.parse_file(full_path);
        } catch e {
            print("Parse failed: " + file_node.path + " - " + str(e));
            return null;
        }
    }

    ability create_ccg_nodes(file_node, ast_data) {
        # Create module node (one per file)
        mod_name = file_node.name.replace(".py", "").replace(".jac", "");
        module_node = spawn node::module {
            name = mod_name,
            file_path = file_node.path
        };
        spawn file_node --> edge::defines to module_node;

        # Create function nodes
        func_nodes = {};
        for func in ast_data.functions {
            f_node = spawn node::function {
                name = func.name,
                docstring = func.docstring,
                file_path = file_node.path
            };
            func_nodes[func.name] = f_node;
            spawn module_node --> edge::contains to f_node;
            spawn file_node --> edge::defines to f_node;
        }

        # Create class nodes
        for cls in ast_data.classes {
            c_node = spawn node::class {
                name = cls.name,
                docstring = cls.docstring,
                file_path = file_node.path
            };
            spawn module_node --> edge::contains to c_node;
            spawn file_node --> edge::defines to c_node;

            # Handle inheritance
            for base in cls.bases {
                # Find or create base class (assume same file for now)
                # In full version: search across files
                base_node = spawn node::class { name = base, file_path = "" };
                spawn c_node --> edge::inherits to base_node;
            }
        }

        # Create variable nodes
        for var in ast_data.variables {
            v_node = spawn node::variable {
                name = var.name,
                file_path = file_node.path
            };
            spawn module_node --> edge::contains to v_node;
            spawn file_node --> edge::defines to v_node;
        }

        # Create call edges (simplified: link all funcs to all calls)
        for call in ast_data.calls {
            callee_name = call.callee;
            # If callee is a known function in this file, link
            if callee_name in func_nodes {
                for caller_node in func_nodes.values() {
                    # In real version: use scope to find true caller
                    spawn caller_node --> edge::calls to func_nodes[callee_name];
                }
            }
        }
    }
}

# ===========================

# 1. Find all callers of a given function
walker get_callers {
    has function_name: str;

    root {
        # Find all function nodes with the given name
        target_funcs = [here --> node::function(name == self.function_name)];
        
        if !target_funcs {
            report {"error": "Function not found: " + self.function_name};
            disengage;
        }

        caller_names = [];
        for target in target_funcs {
            # Find all functions that CALL this target
            callers = [here --> node::function --> edge::calls to target];
            for caller in callers {
                caller_names = caller_names + [caller.name + " (" + caller.file_path + ")"];
            }
        }

        if !caller_names {
            report {"function": self.function_name, "callers": []};
        } else {
            report {"function": self.function_name, "callers": caller_names};
        }
    }
}

# 2. Find all subclasses (children) of a given class
walker get_class_children {
    has class_name: str;

    root {
        # Find the parent class node(s)
        parent_classes = [here --> node::class(name == self.class_name)];
        
        if !parent_classes {
            report {"error": "Class not found: " + self.class_name};
            disengage;
        }

        child_names = [];
        for parent in parent_classes {
            # Find all classes that INHERIT FROM this parent
            children = [here --> node::class --> edge::inherits to parent];
            for child in children {
                child_names = child_names + [child.name + " (" + child.file_path + ")"];
            }
        }

        if !child_names {
            report {"class": self.class_name, "subclasses": []};
        } else {
            report {"class": self.class_name, "subclasses": child_names};
        }
    }
}