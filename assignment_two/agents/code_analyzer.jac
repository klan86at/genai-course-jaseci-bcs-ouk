
# agents/CodeAnalyzer.jac
include agent_core;


# CCG node types
node Module { has name: str; has file_path: str; }
node Function { has name: str; has file_path: str; }
node Class { has name: str; has file_path: str; }
node GraphRoot { has name: str = "root"; }


# CCG edges (implicit via traversal)
node CodeAnalyzer(Toolbox) {
    has parsed_results: dict[str, dict[str, list[str]]] = {};
    has ccg_root: GraphRoot = None;

    def parse_file_with_treesitter(filepath: str) -> bool;
    def build_code_context_graph(file_list: list[str]) -> GraphRoot;
    def get_callers(func_name: str) -> list[str];

    def analyze_codebase(file_list: list[str]) -> str by llm(
        method="ReAct",
        tools=[self.build_code_context_graph, self.get_callers]
    );

    impl CodeAnalyzer.process -> None {
        _ = self.analyze_codebase(["src/main.py", "src/utils.py"]);
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
        self.ccg_root = root ++> GraphRoot(); # isolated subgraph
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