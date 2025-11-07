
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

    # def route_to_node(current_phase: str, context: str) -> RoutingNodes by llm();
    # def route_to_node(github_url: str) -> str by llm(
    #     method="ReAct",
    #     tools=[RepoMapper, CodeAnalyzer, DocGenie],
    #     instructions="You must return exactly one of these tool names as a string: 'RepoMapper', 'CodeAnalyzer', or 'DocGenie'. For new repositories, return 'RepoMapper' first."
    # );


    can start with `root entry {
        print("🚀 Starting CodeGenius...");
        self.status = "running";
        # next = self.route_to_node(self.github_url);
        # print(f"🔍 LLM returned: '{next}'"); 
        self._go_to("RepoMapper");
    }

    can resume with RepoMapper exit {
        print("📁 RepoMapper completed, going to CodeAnalyzer...");
        # next = self.route_to_node(visitor.readme_context);
        self._go_to("CodeAnalyzer");
    }

    can resume with CodeAnalyzer exit {
        print("🔍 CodeAnalyzer completed, going to DocGenie...");
        # next = self.route_to_node(str(keys(visitor.code_metadata)));
        self._go_to("DocGenie");
    }

    can finalize with DocGenie exit {
        self.final_docs = visitor.final_docs;
        self.status = "complete";
        print("✅ Documentation complete.");
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
        print(f"🔍 Looking for node type: '{target}'");
        node_type = target;  # Use target directly
        
        all_nodes = [root -->];
        print(f"📋 Found {len(all_nodes)} connected nodes");
        
        for n in all_nodes {
            node_name = type(n).__name__;
            print(f"🔎 Checking node: '{node_name}'");
            if node_name == node_type {
                print(f"✅ Found matching node: '{node_name}', processing...");
                n.process();
                
                # Manually continue the flow
                if node_type == "RepoMapper" {
                    print("📁 RepoMapper completed, going to CodeAnalyzer...");
                    self._go_to("CodeAnalyzer");
                } elif node_type == "CodeAnalyzer" {
                    print("🔍 CodeAnalyzer completed, going to DocGenie...");
                    self._go_to("DocGenie");
                } elif node_type == "DocGenie" {
                    print("📝 Testing method call...");
                    test_result = n.test_method();
                    print(f"📝 Test result: {test_result}");
                    
                    print("📝 Calling process...");
                    n.process();
                    
                    print("📝 Calling run_process...");
                    n.run_process();
                    
                    docs = n.get_final_docs();
                    print(f"📝 Retrieved docs length: {len(docs)}");
                    self.final_docs = docs;
                    print("✅ Documentation complete.");
                    self.status = "complete";
                }
                return;
            }
        }

        print(f"❌ Node of type '{node_type}' not found under root");
        disengage;
    }
}

with entry {
    github_url = "https://github.com/example/project";

    root ++> RepoMapper();
    root ++> CodeAnalyzer();
    root ++> DocGenie();

    # Spawn and let it run
    walker_instance = CodeGenius(github_url=github_url);
    walker_instance spawn root;

    # Access final_docs directly from the walker
    if walker_instance.final_docs != "" {
        print("\n" + "="*50);
        print(walker_instance.final_docs);
        print("="*50);
    } else {
        print("No documentation generated.");
    }
}
# 