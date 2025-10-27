walker code_genius {
    has repo_url: str;
    root {
        spawn walker::clone_repo with { github_url = self.repo_url };
        spawn walker::generate_file_tree;
        spawn walker::summarize_readme;
        spawn walker::build_ccg;  // ← use this, not analyze_codebase
        spawn walker::generate_docs;
    }
}