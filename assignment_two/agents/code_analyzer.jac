
# nodes/CodeAnalyzer.jac
import from agent_core { Toolbox }

# CCG node types
node Module { has name: str; has file_path: str; }
node Function { has name: str; has file_path: str; }
node Class { has name: str; has file_path: str; }

# CCG edges (implicit via traversal)
node CodeAnalyzer(Toolbox) {
    has ccg_root: node = None;
    has parsed_results: dict = {};

    def parse_file_with_treesitter(filepath: str) -> bool;
    def build_code_context_graph(file_list: list[str]) -> node;
    def get_callers(func_name: str) -> list[str];

    def analyze_codebase(file_list: list[str]) -> str by llm(
        method="ReAct",
        tools=[self.build_code_context_graph, self.get_callers]
    );

    impl CodeAnalyzer.process {
        _ = self.analyze_codebase(visitor.pending_files);
        visitor.code_metadata = self.parsed_results;
        visitor.ccg_root = self.ccg_root;
        visitor.get_callers = self.get_callers;  # expose API
    }

    impl CodeAnalyzer.parse_file_with_treesitter {
        # Create module
        mod_name = filepath.split("/")[-1].replace(".py", "");
        mod = self.ccg_root ++> Module(name=mod_name, file_path=filepath);

        # Stub: add functions
        if "main.py" in filepath {
            train_fn = mod ++> Function(name="train_model", file_path=filepath);
            preprocess_fn = mod ++> Function(name="preprocess_data", file_path=filepath);
            # Add call edge (via containment for now)
            self.parsed_results[filepath] = {
                "functions": ["train_model", "preprocess_data"]
            };
        } else {
            self.parsed_results[filepath] = {"functions": []};
        }
            

        return true;
    }

    impl CodeAnalyzer.build_code_context_graph {
        self.ccg_root = root ++> node();  # isolated subgraph
        for f in file_list {
            self.parse_file_with_treesitter(f);
        }
        return self.ccg_root;
    }

    impl CodeAnalyzer.get_callers {
        if func_name == "train_model" {
            return ["main.py"];
        }
            
        return [];
    }
}
sem CodeAnalyzer.analyze_codebase = """
    Build a Code Context Graph (CCG) from the file list.
    1. Call build_code_context_graph first.
    2. Only call get_callers if explicitly asked about function callers.
    Return: 'Code analysis complete.'
    """;

# # Code Context Graph (CCG) node types
# node Function {
#     has name: str;
#     has file_path: str;
#     has signature: str;
# }

# node Class {
#     has name: str;
#     has file_path: str;
#     has bases: list[str] = [];
# }

# node Module {
#     has name: str;
#     has file_path: str;
# }

# # Relationship edges
# edge Calls { }          # Function → Function
# edge Inherits { }       # Class → Class
# edge Contains { }       # Module → Function/Class
# edge Uses { }           # Function/Class → Module

# node CodeAnalyzer(Toolbox) {
#     # Internal storage for CCG root
#     has ccg_root: node = null;

#     # === TOOL: Parse file and populate CCG ===
#     def parse_file_with_treesitter(filepath: str) -> bool {
#         # ⚙️ Simulated: real impl uses Tree-sitter AST
#         # For demo, we hardcode a simple structure
#         mod = self.ccg_root ++> Module(name="main", file_path=filepath);

#         train_fn = mod +>:Contains:+> Function(name="train_model", file_path=filepath);
#         preprocess_fn = mod +>:Contains:+> Function(name="preprocess_data", file_path=filepath);

#         # train_model calls preprocess_data
#         train_fn +>:Calls:+> preprocess_fn;

#         return true;
#     }

#     # === TOOL: Build full CCG from file list ===
#     def build_code_context_graph(file_list: list[str]) -> node {
#         self.ccg_root = root ++> node();  # Create isolated CCG subgraph
#         for f in file_list {
#             self.parse_file_with_treesitter(f);
#         }
#         return self.ccg_root;
#     }

#     # === QUERY API: Find callers of a function ===
#     def get_callers(func_name: str) -> list[str] {
#         if not self.ccg_root {
#             return [];
#         } 
#         target = self.ccg_root --> (`?Function: name == "{func_name}");
#         if not target {
#             return [];
#         } 
#         callers = target[0] <--(`?Calls);
#         return [c.name for c in callers];
#     }

#     # === QUERY API: Get inheritance chain ===
#     def get_base_classes(class_name: str) -> list[str] {
#         if not self.ccg_root {
#             return [];
#         } 
#         cls = self.ccg_root -->(`?Class: name == "{class_name}");
#         if not cls {
#             return [];
#         } 
#         bases = cls[0] -->(`?Inherits);
#         return [b.name for b in bases];
#     }

#     # === LLM-ORCHESTRATED ENTRY POINT ===
#     def analyze_codebase(file_list: list[str]) -> str by llm(
#         method="ReAct",
#         tools=[self.build_code_context_graph, self.get_callers, self.get_base_classes]
#     );

#     # Entry ability: called by CodeGenius
#     can process with CodeGenius entry {
#         _ = self.analyze_codebase(visitor.pending_files);
#         # Expose CCG root and query APIs to supervisor
#         visitor.ccg_root = self.ccg_root;
#         visitor.get_callers = self.get_callers;
#         visitor.get_base_classes = self.get_base_classes;
#     }
# }

# # import from codeGenius_impl { CodeAnalyzer.parse_file_with_treesitter, CodeAnalyzer.build_code_context_graph, get_callers, nalyze_codebase }

# # node CodeAnalyzer(Toolbox) {
# #     def parse_file_with_treesitter(filepath: str) -> dict;
# #     def infer_high_impact_files(file_tree: dict) -> list[str];

# #     def analyze_codebase(file_list: list[str], file_tree: dict) -> str by llm(
# #         method="ReAct",
# #         tools=[self.parse_file_with_treesitter, self.infer_high_impact_files]
# #     );

# #     can process with CodeGenius entry {
# #         result = self.analyze_codebase(
# #             file_list=keys(visitor.repo_structure),
# #             file_tree=visitor.repo_structure
# #         );
# #         visitor.code_metadata = self.parsed_results;  # populated by parse_file_with_treesitter
# #     }
# # }