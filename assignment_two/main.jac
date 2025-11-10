
# main.jac

# import from agents { repo_mapper, code_analyzer, doc_genie }

include agents.repo_mapper;
include agents.code_analyzer;
include agents.doc_genie;
include agent_core;


import from byllm.llm { Model }
# glob llm = Model(model_name="openai/gpt-4o-mini", verbose=False);
glob llm = Model(model_name="gemini/gemini-2.0-flash-001", verbose=False);
# glob llm = Model(model_name="groq/llama-3.1-8b-instant", verbose=False);


enum RoutingNodes {
    repo_mapper = "RepoMapper",
    code_analyzer = "CodeAnalyzer",
    doc_genie = "DocGenie"
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
    def clone_repo(url: str) -> str {
    return "RepoMapper should handle this";
    }

    def analyze_code(url: str) -> str {
        return "CodeAnalyzer should handle this";
    }

    def generate_docs(url: str) -> str {
        return "DocGenie should handle this";
    }
    def _go_to(target: str) -> None {
        all_nodes = [root -->];
        
        for n in all_nodes {
            node_name = type(n).__name__;
            if node_name == target {
                if target == "DocGenie" {
                    n.run_process();
                    self.final_docs = n.get_final_docs();
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
                    n.process();
                    if target == "RepoMapper" {
                        next = self.route_to_node("repository mapped").strip();
                        self._go_to(next);
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
    github_url = "https://github.com/octocat/Hello-World";

    root ++> RepoMapper();
    root ++> CodeAnalyzer();
    root ++> DocGenie();

    # Spawn and let it run
    walker_instance = CodeGenius(github_url=github_url);
    walker_instance spawn root;

    if walker_instance.final_docs != "" {
        print("\n" + "="*50);
        print(walker_instance.final_docs);
        print("="*50);
    } else {
        print("No documentation generated.");
    }
}