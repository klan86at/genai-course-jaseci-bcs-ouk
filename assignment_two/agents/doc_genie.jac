# agents/doc_genie.jac

import from agent_core { Toolbox }
import from byllm.llm { Model }

glob llm = Model(model_name="gemini/gemini-2.0-flash-001", verbose=False);

node DocGenie(Toolbox) {
    has final_markdown: str = "";

    def render_overview(readme_summary: str) -> str;
    def render_installation(file_tree: dict[str, str]) -> str;
    def render_usage(file_tree: dict[str, str]) -> str;
    def render_api_reference(code_meta: dict[str, dict[str, list[str]]]) -> str;
    def generate_diagram(code_meta: dict[str, dict[str, list[str]]]) -> str;

    def generate_documentation(
        readme_summary: str,
        file_tree: dict[str, str],
        code_meta: dict[str, dict[str, list[str]]]
    ) -> str by llm(
        method="ReAct",
        tools=[
            self.render_overview,
            self.render_installation,
            self.render_usage,
            self.render_api_reference,
            self.generate_diagram
        ]
    );

    def get_final_docs() -> str {
        return self.final_markdown;
    }

    def test_method() -> str {
        print("📝 TEST: DocGenie test_method called!");
        return "test works";
    }

    def run_process() -> None {
        overview = self.render_overview("AI DocGen: Auto-generates developer documentation from source code.");
        installation = self.render_installation({"src/main.py": "file", "README.md": "file", "requirements.txt": "file"});
        usage = self.render_usage({"src/main.py": "file", "README.md": "file"});
        api_ref = self.render_api_reference({"src/main.py": {"functions": ["train_model", "preprocess_data"]}});
        diagram = self.generate_diagram({"src/main.py": {"functions": ["train_model", "preprocess_data"]}});
        
        self.final_markdown = overview + "\n" + installation + "\n" + usage + "\n" + api_ref + "\n" + diagram;
    }
}

impl DocGenie.process -> None {
    print("📝 DocGenie: Starting process method...");
    
    # Test with static content first
    self.final_markdown = "# Test Documentation\n\nThis is a test document.";
    print(f"📝 Static docs length: {len(self.final_markdown)}");
    
    # Try LLM call
    print("📝 Calling LLM...");
    md = self.generate_documentation(
        "AI DocGen: Auto-generates developer documentation from source code.",
        {"src/main.py": "file", "README.md": "file"},
        {"src/main.py": {"functions": ["train_model", "preprocess_data"]}}
    );
    print(f"📝 LLM returned: {len(md)} characters");
    
    if len(md) > 0 {
        self.final_markdown = md;
    }
    
    print(f"📝 Final markdown length: {len(self.final_markdown)}");
    print("📝 DocGenie: Completed documentation generation.");
}

impl DocGenie.render_overview {
    return "## 📌 Project Overview\n\n" + readme_summary + "\n";
}

impl DocGenie.render_installation {
    if "requirements.txt" in file_tree {
        return "## ⚙️ Installation\n\n```bash\npip install -r requirements.txt\n```\n";
    }
    return "## ⚙️ Installation\n\nRefer to the repository for setup.\n";
}

impl DocGenie.render_usage {
    has_main = ("main.py" in file_tree) or ("src/main.py" in file_tree);
    if has_main {
        return "## ▶️ Usage\n\n```bash\npython main.py\n```\n";
    }
    return "## ▶️ Usage\n\nSee source files for entry points.\n";
}

impl DocGenie.render_api_reference {
    if not code_meta {
        return "## 📚 API Reference\n\nNo API elements detected.\n";
    }
    result = "## 📚 API Reference\n\n";
    for file in code_meta {
        meta = code_meta[file];
        result += "### `" + file + "`\n";
        if "functions" in meta {
            functions = meta["functions"];
            for fn in functions {
                result += "- **`" + fn + "`** – _Function description placeholder._\n";
            }
        }
        result += "\n";
    }
    return result;
}

impl DocGenie.generate_diagram {
    return "## 🖼️ System Diagram\n\n```mermaid\ngraph LR\n  main.py --> train_model\n  train_model --> preprocess_data\n```\n";
}

# Semantic instruction for LLM
sem DocGenie.generate_documentation = """
Generate a complete markdown document with these sections in order:
1. Project Overview
2. Installation
3. Usage
4. API Reference
5. System Diagram
Call each rendering tool exactly once.
Return the full markdown as a single string.
""";
