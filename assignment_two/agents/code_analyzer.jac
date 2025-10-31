# import from codeGenius_impl { CodeAnalyzer.parse_file_with_treesitter, CodeAnalyzer.build_code_context_graph, get_callers, nalyze_codebase }

node CodeAnalyzer(Toolbox) {
    def parse_file_with_treesitter(filepath: str) -> dict;
    def infer_high_impact_files(file_tree: dict) -> list[str];

    def analyze_codebase(file_list: list[str], file_tree: dict) -> str by llm(
        method="ReAct",
        tools=[self.parse_file_with_treesitter, self.infer_high_impact_files]
    );

    can process with CodeGenius entry {
        result = self.analyze_codebase(
            file_list=keys(visitor.repo_structure),
            file_tree=visitor.repo_structure
        );
        visitor.code_metadata = self.parsed_results;  # populated by parse_file_with_treesitter
    }
}