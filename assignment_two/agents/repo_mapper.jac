# repo_mapper
import from byllm { Model }
include graphs.code_base_graph;

# Global LLM instance 
glob llm = Model(model_name="gemini/gemini-2.0-flash-001", verbose=False);

walker clone_repo {
    has github_url: str;

    root {
        try{
            # Validate and clone repo using python helper
            cloned_path = py::py_helpers.clone_repo(self.github_url);
            print("Repo cloned to: " + cloned_path);
            report{
                "status": "success",
                "cloned_path": cloned_path,
                "repo_url": self.github_url
            };
        } catch e {
            error_msg = " Cloning failed: " + str(e);
            print(error_msg);
            report {
                "status": "error",
                "message": error_msg,
                "repo_url": self.github_url
            };
        }
    }
}

walker generate_file_tree {
    has directory_path: str;

    root {
        # Create repo root node
        repo_node = create node repo with {
            local_path: self.directory_path;
        };

        # Build file tree recursively
        self.build_tree(self.directory_path, repo_node);

        report {
            "status": "success",
            "repo_node_id": jid(repo_node),
            "directory": self.directory_path
        };
    }
    # Recursive helper to build graph
    ability build_tree(current_path: str, parent_node) {
        ignore_dirs = {".git", "__pycache__", "node_modules", ".venv", "venv", "myenv", "jac-env", "dist", "build"};
        entries = py::os.listdir(current_path);

        for entry in entries {
            abs_path = py::os.path.join(current_path, entry);
            rel_path = py::os.path.relpath(abs_path, self.directory_path);

            # Skip ignored directories
            if py::os.path.isdir(abs_path) and entry in ignore_dirs {
                continue;
            }

            if py::os.path.isdir(abs_path) {
                folder_node = spawn node::folder {
                    name = entry,
                    path = rel_path
                };
                spawn parent_node --> edge::contains to folder_node;
                # Recurse into subdirectory
                self.build_tree(abs_path, folder_node);
            } esle {
                # Determine language from file extension
                lang = "unknown";
                if entry.endswith(".py") {lang = "python"; }
                elif entry.endswith(".jac") {lang = "jac"; }
                elif entry.endswith((".js", ".ts")) { lang = "javascript"; }

                file_node - spawn node::file {
                    name = entry,
                    path = rel_path,
                    language = lang
                };
                spawn parent_node --> edge::contains to file_node;
            }
        }
    }
}

wlaker summarize_readme {
    root {
        # Start from repo node
        take --> node::repo;
    }

    repo {
        # Find README files in the file tree
        readme_files = --> node::file(
            name in ["README.md", "README.rst", "README", "readme.md", "readme"]
        );

        if !readme_files {
            print("No README found.");
            report {"status": "no_readme"};
            return;
        }

        fro readme in readme_files {
            # Read file content via Python helper
            abs_path = py::os.path.join(repo.local_path, readme.path);
            try {
                content = py::open(abs_path, 'r', encoding='utf-8').read();
                readme.content = content; # store raw content

                # Generate summary via llm
                prompt = "Summarize this README in 3 - 4 clear concise sentences:\n\n" + content[:4000];
                summary = llm.generate(prompt);
                readme.summary = summary; # store summary on file node

                print("Summarized: " + readme.path);
            } catch e {
                print("Failed to read or summarize " + readme.path + ": " + str(e));
            }
        }

        report {"status": "success", "readme_count": len(readme_files)};
    }
}