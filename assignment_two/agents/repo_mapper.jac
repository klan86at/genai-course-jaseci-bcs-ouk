# RepoMapper.jac
import os;
import subprocess;
import shutil;
import from agent_core { Toolbox }
node RepoMapper(Toolbox) {
    has file_tree: dict[str, str] = {};
    has readme_summary: str = "";
    has repo_path: str = "";
    has ignore_patterns: list[str] = [
        ".git", "node_modules", "__pycache__", ".pytest_cache",
        "*.pyc", "*.pyo", "*.pyd", ".DS_Store", "Thumbs.db",
        "*.log", "*.tmp", "*.swp", "*.bak", "dist", "build"
    ];

    def clone_repository(github_url: str) -> str;
    def build_file_tree(repo_path: str) -> dict[str, str];
    def parse_gitignore(repo_path: str) -> list[str];
    def should_ignore(file_path: str, patterns: list[str]) -> bool;
    def summarize_readme(repo_path: str) -> str;
    def walk_directory(current_path: str, base_path: str) -> None;

    def map_repository(github_url: str) -> str by llm(
        method="ReAct",
        tools=[self.clone_repository, self.build_file_tree, self.summarize_readme]
    );

    impl RepoMapper.process -> None {
        _ = self.map_repository(visitor.github_url);
    }

    impl RepoMapper.clone_repository {
        
        repo_name = github_url.split("/")[-1].replace(".git", "");
        self.repo_path = f"./temp_repos/{repo_name}";
        
        # Create temp directory
        temp_path = "./temp_repos";
        if not os.path.exists(temp_path) {
            os.makedir(temp_path);
        }
        
        # Remove existing if exists
        if os.path.exists(self.repo_path) {
            os.system(f"rm -rf {self.repo_path}");
        }
        
        # Clone repository
        cmd = f"git clone {github_url} {self.repo_path}";
        result = os.system(cmd);
        
        if result == 0 {
            return f"Successfully cloned {github_url}";
        } else {
            return f"Failed to clone {github_url}";
        }
    }

    impl RepoMapper.build_file_tree {        
        if not os.path.exists(repo_path) {
            return {};
        }
        
        self.file_tree = {};
        self.walk_directory(repo_path, repo_path);
        return self.file_tree;
        
        # Simple directory walk using os.listdir recursively
    impl RepoMapper.walk_directory {
        try {
            items = os.listdir(current_path);
            for item in items {
                item_path = os.path.join(current_path, item);
                rel_path = os.path.relpath(item_path, base_path);
                
                if os.path.isfile(item_path) {
                    # File type logic here
                    if item.endswith(".py") or item.endswith(".js") {
                        self.file_tree[rel_path] = "source";
                    }
                } elif os.path.isdir(item_path) and not self.should_ignore(item, self.ignore_patterns) {
                    self.walk_directory(item_path, base_path);  # ← Recursive call to self
                }
            }
        } except Exception {
            return;
        }
    }
        
        walk_directory(repo_path, repo_path);
        return self.file_tree;
    }

    impl RepoMapper.parse_gitignore {
        
        gitignore_path = os.path.join(repo_path, ".gitignore");
        patterns = [];
        
        if os.path.exists(gitignore_path) {
            try {
                with open(gitignore_path, "r") as f {
                    content = f.read();
                    lines = content.split("\n");
                    for line in lines {
                        line = line.strip();
                        if line and not line.startswith("#") {
                            patterns.append(line);
                        }
                    }
                }
            } except Exception {
                return;
            }
        }
        
        return patterns;
    }

    impl RepoMapper.should_ignore {
        # Enhanced pattern matching without fnmatch
        for pattern in patterns {
            # Handle wildcard patterns
            if pattern.startswith("*.") {
                extension = pattern[1:];
                if file_path.endswith(extension) {
                    return True;
                }
            } elif pattern.endswith("*") {
                prefix = pattern[:-1];
                if file_path.startswith(prefix) {
                    return True;
                }
            } elif pattern in file_path {
                return True;
            }
        }
        return False;
    }

    impl RepoMapper.summarize_readme {
        
        readme_files = ["README.md", "README.txt", "README.rst", "readme.md"];
        
        for readme_file in readme_files {
            readme_path = os.path.join(repo_path, readme_file);
            if os.path.exists(readme_path) {
                try {
                    with open(readme_path, "r", encoding="utf-8") as f {
                        content = f.read()[:1000];  # First 1000 chars
                        
                        # Extract meaningful lines
                        lines = content.split("\n");
                        summary_lines = [];
                        for line in lines {
                            line = line.strip();
                            if line and not line.startswith("#") and len(summary_lines) < 3 {
                                summary_lines.append(line);
                            }
                        }
                        
                        if summary_lines {
                            self.readme_summary = " ".join(summary_lines);
                        } else {
                            self.readme_summary = "Repository documentation available.";
                        }
                        return self.readme_summary;
                    }
                } except Exception {
                    continue;
                }
            }
        }
        
        self.readme_summary = "No README file found.";
        return self.readme_summary;
    }
}
sem RepoMapper.map_repository = """
    Analyze the GitHub repository by following these steps:
    1. Call clone_repository to clone the GitHub repository locally
    2. Call build_file_tree to scan and categorize all files (respects .gitignore)
    3. Call summarize_readme to extract project description from README
    Return: 'Repository mapped successfully with X files found.'
    """;