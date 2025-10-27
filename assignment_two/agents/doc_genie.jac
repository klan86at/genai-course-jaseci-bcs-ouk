include graphs.code_base_graph;

walker generate_markdown {
    root {
        repo_nodes = [here --> node::repo];
        if !repo_nodes {
            report {"error": "No repository found in graph."};
            disengage;
        }
        repo = repo_nodes[0];

        md = "";

        # 1. Project Overview
        md += self.build_overview_section(repo);

        # 2. Repository Structure
        md += self.build_structure_section(repo);

        # 3. Installation & Setup
        md += self.build_installation_section();

        # 4. Core Modules & API Reference
        md += self.build_api_reference_section(repo);

        # 5. Function Relationships (Call Graph)
        md += self.build_relationships_section();

        # Save to file
        repo_name = "unknown";
        if repo.url {
            repo_name = repo.url.split("/")[-1].replace(".git", "");
        }
        output_path = "./outputs/" + repo_name + "/docs.md";
        py::os.makedirs(py::os.path.dirname(output_path), exist_ok=True);
        py::open(output_path, "w").write(md);

        print("✅ Documentation saved to: " + output_path);
        report {"status": "success", "output_path": output_path};
    }

    ability build_overview_section(repo) {
        section = "# Project Overview\n\n";
        readme_files = [repo --> node::file(name in ["README.md", "readme.md"])];
        if readme_files and readme_files[0].summary {
            section += readme_files[0].summary + "\n\n";
        } else {
            section += "No README summary available.\n\n";
        }
        return section;
    }

    ability build_structure_section(repo) {
        section = "# Repository Structure\n\n";
        section += "```\n";
        section += self.render_tree(repo, 0);
        section += "```\n\n";
        return section;
    }

    ability render_tree(node, depth) {
        indent = "  " * depth;
        if jtype(node) == "folder" {
            result = indent + "📁 " + node.name + "/\n";
            children = node --> node::folder + node --> node::file;
            for child in children {
                result += self.render_tree(child, depth + 1);
            }
            return result;
        } else if jtype(node) == "file" {
            return indent + "📄 " + node.name + "\n";
        } else {
            # repo root
            result = node.local_path.split("/")[-1] + "/\n";
            children = node --> node::folder + node --> node::file;
            for child in children {
                result += self.render_tree(child, 1);
            }
            return result;
        }
    }

    ability build_installation_section() {
        return """# Installation & Setup
    }
}
        

```bash
# Clone the repository
git clone <REPO_URL>

# Install dependencies
pip install -r requirements.txt

# Run the application
python main.py