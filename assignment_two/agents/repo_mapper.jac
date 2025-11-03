# RepoMapper.jac
include agent_core;
node RepoMapper(Toolbox) {
    has file_tree: dict = {};
    has readme_summary: str = "";

    def build_file_tree(github_url: str) -> dict;
    def summarize_readme(github_url: str) -> str;

    def map_repository(github_url: str) -> str by llm(
        method="ReAct",
        tools=[self.build_file_tree, self.summarize_readme]
    );

    impl RepoMapper.process {
        _ = self.map_repository(visitor.github_url);
        visitor.repo_structure = self.file_tree;
        visitor.readme_context = self.readme_summary;
    }

    impl RepoMapper.build_file_tree {
        # Stub: real impl would clone & walk files
        self.file_tree = {
            "src/": {"main.py": {}, "utils.py": {}},
            "README.md": {},
            "requirements.txt": {}
        };
        return self.file_tree;
    }

    impl RepoMapper.summarize_readme {
        self.readme_summary = "AI DocGen: Auto-generates developer documentation from source code.";
        return self.readme_summary;
    }
}
sem RepoMapper.map_repository = """
    Analyze the GitHub repository.
    1. Call build_file_tree to get the file structure (ignore .git, node_modules).
    2. Call summarize_readme to get a one-sentence project summary.
    Return: 'Repository mapped successfully.'
    """;