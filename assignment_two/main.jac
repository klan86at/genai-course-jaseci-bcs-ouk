# main.jac

# import from agents { repo_mapper, code_analyzer, doc_genie }
include agents.repo_mapper;
include agents.code_analyzer;
include agents.doc_genie;
include agent_core;

import from byllm.llm { Model }
# glob llm = Model(model_name="openai/gpt-4o-mini", verbose=False);
glob llm = Model(model_name="gemini/gemini-2.0-flash-001", verbose=False);

enum RoutingNodes {
    repo_mapper = "RepoMapper",
    code_analyzer = "CodeAnalyzer",
    doc_genie = "DocGenie"
}

# API Walker for web endpoints
walker DocumentationAPI {
    has github_url: str;
    has status: str = "idle";
    has final_docs: str = "";
    has error_message: str = "";

    can generate_docs with `root entry {
        try {
            # Create nodes
            repo_mapper = root ++> RepoMapper();
            code_analyzer = root ++> CodeAnalyzer();
            doc_genie = root ++> DocGenie();
            
            # Step 1: Clone and map repository
            clone_result = repo_mapper.clone_repository(self.github_url);
            if "Failed" in clone_result {
                self.error_message = clone_result;
                self.status = "error";
                return {"status": "error", "message": clone_result};
            }
            
            # Step 2: Build file tree
            file_tree = repo_mapper.build_file_tree(repo_mapper.repo_path);
            repo_mapper.summarize_readme(repo_mapper.repo_path);
            
            # Step 3: Analyze code
            file_list = [];
            for file_path in file_tree {
                if file_tree[file_path] == "source" {
                    full_path = repo_mapper.repo_path + "/" + file_path;
                    file_list.append(full_path);
                }
            }
            code_analyzer.file_list = file_list;
            code_analyzer.process();
            
            # Step 4: Generate documentation
            doc_genie.process();
            
            self.final_docs = doc_genie.get_final_docs();
            self.status = "complete";
            
            return {
                "status": "success",
                "documentation": self.final_docs,
                "file_count": len(file_list)
            };
            
        } except Exception as e {
            self.error_message = f"Error: {str(e)}";
            self.status = "error";
            return {"status": "error", "message": self.error_message};
        }
    }
}

# Health check walker
walker HealthCheck {
    can check with `root entry {
        return {"status": "healthy", "service": "CodeGenius API"};
    }
}

walker CodeGenius {
    has github_url: str;
    has status: str = "idle";
    has final_docs: str = "";

    def route_to_node(context: str) -> str by llm(
        method="ReAct",
        instructions="Based on the context, return exactly one node name: 'RepoMapper', 'CodeAnalyzer', or 'DocGenie'. For new repositories or URLs, return 'RepoMapper'. After repository mapping, return 'CodeAnalyzer'. After code analysis, return 'DocGenie'."
    );


    can start with `root entry {
        self.status = "running";
        next = self.route_to_node(self.github_url).strip();
        self._go_to(next);
    }

    can resume with RepoMapper exit {
        next = self.route_to_node("repository mapped");
        self._go_to(next);
    }

    can resume with CodeAnalyzer exit {
        next = self.route_to_node("code analyzed");
        self._go_to(next);
    }

    can finalize with DocGenie exit {
        self.final_docs = visitor.final_docs;
        self.status = "complete";
        disengage;
    }

    def _go_to(target: str) -> None {
        all_nodes = [root -->];
        
        for n in all_nodes {
            node_name = type(n).__name__;
            if node_name == target {
                if target == "DocGenie" {
                    # Get data from RepoMapper and CodeAnalyzer
                    repo_mapper_node = None;
                    code_analyzer_node = None;
                    
                    for rn in all_nodes {
                        if type(rn).__name__ == "RepoMapper" {
                            repo_mapper_node = rn;
                        } elif type(rn).__name__ == "CodeAnalyzer" {
                            code_analyzer_node = rn;
                        }
                    }
                    
                    # Call process to generate documentation
                    n.process();
                    
                    # Get the generated documentation
                    self.final_docs = n.get_final_docs();
                    
                    # If no docs generated, create a simple summary
                    if len(self.final_docs) == 0 {
                        summary = "# Repository Documentation" + "\n\n";
                        if repo_mapper_node {
                            summary += "## Overview" + "\n" + repo_mapper_node.readme_summary + "\n\n";
                            summary += "## Files" + "\n" + "Found " + str(len(repo_mapper_node.file_tree)) + " files" + "\n";
                        }
                        self.final_docs = summary;
                    }
                    
                    self.status = "complete";
                } elif target == "CodeAnalyzer" {
                    # Pass file list from RepoMapper to CodeAnalyzer
                    repo_mapper_node = None;
                    for rn in all_nodes {
                        if type(rn).__name__ == "RepoMapper" {
                            repo_mapper_node = rn;
                            break;
                        }
                    }
                    
                    if repo_mapper_node and repo_mapper_node.file_tree {
                        file_list = [];
                        for file_path in repo_mapper_node.file_tree {
                            file_type = repo_mapper_node.file_tree[file_path];
                            if file_type == "source" {
                                full_path = f"{repo_mapper_node.repo_path}/{file_path}";
                                file_list.append(full_path);
                            }
                        }
                        n.file_list = file_list;
                    }
                    
                    n.process();
                    next = self.route_to_node("code analyzed").strip();
                    self._go_to(next);
                } else {
                    if target == "RepoMapper" {
                        # Pass github_url to RepoMapper and process
                        print("\n🔄 Cloning repository...");
                        clone_result = n.clone_repository(self.github_url);
                        print("  - Clone result: " + clone_result);
                        
                        print("📂 Building file tree...");
                        n.build_file_tree(n.repo_path);
                        print("  - Files found: " + str(len(n.file_tree)));
                        
                        print("📝 Reading README...");
                        n.summarize_readme(n.repo_path);
                        print("  - README summary length: " + str(len(n.readme_summary)));
                        
                        next = self.route_to_node("repository mapped").strip();
                        self._go_to(next);
                    } else {
                        n.process();
                    }
                }
                return;
            }
        }
        disengage;
    }
}

sem CodeGenius.route_to_node = """
Determine the next processing node based on the current context:
- For new GitHub URLs or initial requests: return "RepoMapper"
- After repository mapping is complete: return "CodeAnalyzer" 
- After code analysis is complete: return "DocGenie"
Return only the node name as a string.
""";

with entry {
    # Check if running as server or CLI
    import sys;
    
    if "serve" in str(sys.argv) {
        # Server mode - API endpoints available
        print("🎰 CodeGenius API Server Started!");
        print("📡 Available endpoints:");
        print("  POST /generate_docs - Generate documentation");
        print("  GET  /check         - Health check");
        print("🌐 Server running on http://localhost:8000");
        print("\n📝 Example usage:");
        print("curl -X POST http://localhost:8000/generate_docs \\");
        print('  -H "Content-Type: application/json" \\');
        print("  -d @data.json");

    } else {
        # CLI mode - interactive
        github_url = input("Enter Github repository URL: ");

        root ++> RepoMapper();
        root ++> CodeAnalyzer();
        root ++> DocGenie();

        # Spawn and let it run
        print(f"🔄 Processing repository: {github_url}");
        walker_instance = CodeGenius(github_url=github_url);
        walker_instance spawn root;

        print(f"📊 Walker status: {walker_instance.status}");
        print(f"📄 Final docs length: {len(walker_instance.final_docs)}");
        
        if walker_instance.final_docs != "" {
            print("\n" + "="*50);
            print(walker_instance.final_docs);
            print("="*50);
        } else {
            print("❌ No documentation generated.");
            print("🔍 Checking individual components...");
            
            # Check if nodes were created and processed
            all_nodes = [root -->];
            for node in all_nodes {
                node_type = type(node).__name__;
                print(f"  - Found node: {node_type}");
                
                if node_type == "DocGenie" {
                    docs = node.get_final_docs();
                    print(f"  - DocGenie docs length: {len(docs)}");
                    if len(docs) > 0 {
                        print(f"  - DocGenie content preview: {docs[:100]}...");
                    }
                }
            }
        }
    }
}