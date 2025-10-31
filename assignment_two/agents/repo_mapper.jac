import from impl { repo_mapper_impl}

node RepoMapper(toolbox) {
    has file_tree: dict = {};
    has readme_summary: str = "";
    has ignored_dirs: list[str] = [".git", "node_modules", "__pycache__", "dist", "build", "myenv", "venv"];
    has ignored_files: list[str] = ["*.log", "*.tmp", "package-lock.json", "uv-lock"];

    # === TOOL: Clone repo and build filtered file tree ===
    def build_file_tree(github_url: str) -> dict {
        # Simulated for now
        self.file_tree = {
            "src/": {
                "main.py": {},
                "core/": {"engine.py": {}, "__init__.py": {}}
            },
            "README.md": {},
            "requirements.txt": {}
        };
        return self.file_tree;
    }

    # === TOOL: Extract and summarize README.md ===
    def summarize_readme(github_url: str) -> str {
        raw_readme = "# AI DocGen\nA tool that auto-generates developer docs from code.";
        self.readme_summary = "AI DocGen: Automatically generates clear, structured documentation from source code using LLMs and static analysis.";
        return self.readme_summary;
    }

    # === PHASE 1: PLAN GENERATION ===
    def generate_plan(github_url: str) -> list[str] by llm(
        prompt="You are a repository analyst. Given a GitHub URL, outline a step-by-step plan to understand the repo structure and purpose. "
               "Available actions: [build_file_tree, summarize_readme]. "
               "Return a JSON list of action names in execution order, e.g., [\"build_file_tree\", \"summarize_readme\"].",
        output_schema={"type": "array", "items": {"type": "string"}}
    );

    # === PHASE 2: EXECUTE PLAN ===
    def execute_plan(plan: list[str], github_url: str) -> dict {
        results = {};
        for step in plan:
            if step == "build_file_tree":
                results["file_tree"] = self.build_file_tree(github_url);
            elif step == "summarize_readme":
                results["readme_summary"] = self.summarize_readme(github_url);
            else:
                # Optional: log unknown step
                continue;
        return results;
    }

    # === PLAN-AND-EXECUTE ORCHESTRATOR ===
    def map_repository(github_url: str) -> str {
        # 1. Generate plan
        plan = self.generate_plan(github_url);
        
        # 2. Execute plan
        outcomes = self.execute_plan(plan, github_url);
        
        # 3. Store results
        if "file_tree" in outcomes:
            self.file_tree = outcomes["file_tree"];
        if "readme_summary" in outcomes:
            self.readme_summary = outcomes["readme_summary"];
        
        return "Repository mapping completed via Plan-and-Execute.";
    }

    # === Entry ability: triggered by CodeGenius walker ===
    can process with CodeGenius entry {
        _ = self.map_repository(visitor.github_url);
        visitor.repo_structure = self.file_tree;
        visitor.readme_context = self.readme_summary;
    }
}