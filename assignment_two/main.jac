
# main.jac

include agent_core;
include agents.repo_mapper;
include agents.code_analyzer;
include agents.doc_genie;


import from byllm.llm { Model }
glob llm = Model(model_name="openai/gpt-4o-mini", verbose=False);
# glob llm = Model(model_name="gemini/gemini-2.0-flash-001", verbose=False);

enum RoutingNodes {
    REPO_MAPPER = "RepoMapper",
    CODE_ANALYZER = "CodeAnalyzer",
    DOC_GENIE = "DocGenie"
}

walker CodeGenius {
    has github_url: str;
    has status: str = "idle";
    has final_docs: str = "";

    def route_to_node(current_phase: str, context: str) -> RoutingNodes by llm();

    can start with `root entry {
        self.status = "running";
        next = self.route_to_node("init", self.github_url);
        self._go_to(next);
    }

    can resume with RepoMapper exit {
        next = self.route_to_node("after_mapping", visitor.readme_context);
        self._go_to(next);
    }

    can resume with CodeAnalyzer exit {
        next = self.route_to_node("after_analysis", str(keys(visitor.code_metadata)));
        self._go_to(next);
    }

    can finalize with DocGenie exit {
        self.final_docs = visitor.final_docs;
        self.status = "complete";
        print("✅ Documentation complete.");
        disengage;
    }

    def _go_to(target: RoutingNodes) -> None {
    node_type = "";
    if target == RoutingNodes.REPO_MAPPER {
        node_type = "RepoMapper";
    } elif target == RoutingNodes.CODE_ANALYZER {
        node_type = "CodeAnalyzer";
    } elif target == RoutingNodes.DOC_GENIE {
        node_type = "DocGenie";
    } else {
        print("❌ Unknown routing target");
        disengage;
        return;
    }

    all_nodes = [root -->];
    for n in all_nodes {
        if type(n).__name__ == node_type {
            n spawn CodeGenius(github_url=self.github_url);
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
    root spawn CodeGenius(github_url=github_url);

    # Since CodeGenius sets visitor.final_docs on DocGenie,
    # and DocGenie is attached to root, you can retrieve it like this:
    doc_genie_node = [root --> (`?DocGenie)];
    if doc_genie_node {
        final_output = doc_genie_node[0].final_markdown;
        if final_output != "" {
            print("\n" + "="*50);
            print(final_output);
            print("="*50);
        }
    }
}
# with entry {
#     # Input
#     github_url = "https://github.com/example/project";

#     # Attach workers to root
#     root ++> RepoMapper();
#     root ++> CodeAnalyzer();
#     root ++> DocGenie();

#     # Launch
#     supervisor = CodeGenius(github_url=github_url);
#     root spawn CodeGenius(github_url=github_url);

#     # Output
#     if supervisor.status == "complete" {
#         print("\n" + "="*50);
#         print(supervisor.final_docs);
#         print("="*50);
#     }
        
# }
# include agent_core;
# include agents.RepoMapper;
# include agents.CodeAnalyzer;
# include agents.DocGenie;

# import from byllm.llm { Model }
# glob llm = Model(model_name="gemini/gemini-2.0-flash-001", verbose=False);

# enum RoutingNodes {
#     REPO_MAPPER, CODE_ANALYZER, DOC_GENIE
# }

# node AnalysisSession {
#     has github_url: str;
#     has repo_structure: dict = {};
#     has documented_files: list[str] = [];
#     has final_docs: str = "";
#     has status: str = "idle";
# }

# walker CodeGenius {
#     has session: AnalysisSession;

#     def route_to_node(phase: str, context: str) -> str by llm();

#     can start with `root entry {
#         session_node = [root --> (`?AnalysisSession)];
#         if not session_node {
#             self.session = root ++> AnalysisSession(github_url=visitor.github_url);
#         } else {
#             self.session = session_node[0];
#         }
#         self._route_and_visit("init", self.session.github_url);
#     }

#     can resume with RepoMapper exit {
#         self.session.repo_structure = visitor.repo_structure;
#         self._route_and_visit("mapped", str(visitor.readme_summary));
#     }

#     can resume with CodeAnalyzer exit {
#         # update session with analyzed files
#         self._route_and_visit("analyzed", "Files processed: " + str(visitor.analyzed));
#     }

#     can finalize with DocGenie exit {
#         self.session.final_docs = visitor.docs;
#         self.session.status = "complete";
#         print("✅ Docs:\n", self.session.final_docs);
#         disengage;
#     }

#     def _route_and_visit(phase: str, context: str) {
#         decision = self.route_to_node(phase, context).strip().upper();
#         target = switch (decision) {
#     case "REPO_MAPPER": RepoMapper;
#     case "CODE_ANALYZER": CodeAnalyzer;
#     case "DOC_GENIE": DocGenie;
#     default: DocGenie;
#         };
#         visit [-->(`?target)] else {
#             report "Agent not available";
#             disengage;
#         }
#     }
# }

# with entry {
#     root ++> RepoMapper();
#     root ++> CodeAnalyzer();
#     root ++> DocGenie();
#     root ++> AnalysisSession(github_url="https://github.com/example/project");

#     root spawn CodeGenius;
# }