# agents/doc_genie.jac

import from agent_core { Toolbox }

node DocGenie(Toolbox) {
    def render_overview(readme_summary: str) -> str;
}
impl DocGenie.render_overview {
    return "Test";
}

# node DocGenie(Toolbox) {
#     has final_markdown: str = "";

#     def render_overview(readme_summary: str) -> str;
#     def render_installation(file_tree: dict) -> str;
#     def render_usage(file_tree: dict) -> str;
#     def render_api_reference(code_meta: dict) -> str;
#     def generate_diagram(code_meta: dict) -> str;

#     def generate_documentation(
#         readme_summary: str,
#         file_tree: dict,
#         code_meta: dict
#     ) -> str by llm(
#         method="ReAct",
#         tools=[
#             self.render_overview,
#             self.render_installation,
#             self.render_usage,
#             self.render_api_reference,
#             self.generate_diagram
#         ]
#     );
# }

# # Implementations (outside node)
# impl DocGenie.process {
#     md = self.generate_documentation(
#         visitor.readme_context,
#         visitor.repo_structure,
#         visitor.code_metadata
#     );
#     self.final_markdown = md;
#     visitor.final_docs = md;
# }

# impl DocGenie.render_overview {
#     return f"## 📌 Project Overview\n\n{readme_summary}\n";
# }

# impl DocGenie.render_installation {
#     if "requirements.txt" in keys(file_tree) {
#         return "## ⚙️ Installation\n\n```bash\npip install -r requirements.txt\n```\n";
#     }
#     return "## ⚙️ Installation\n\nRefer to the repository for setup.\n";
# }

# impl DocGenie.render_usage {
#     file_keys = keys(file_tree);
#     has_main = ("main.py" in file_keys) or ("src/main.py" in file_keys);
#     if has_main {
#         return "## ▶️ Usage\n\n```bash\npython main.py\n```\n";
#     }
#     return "## ▶️ Usage\n\nSee source files for entry points.\n";
# }

# impl DocGenie.render_api_reference {
#     if not code_meta {
#         return "## 📚 API Reference\n\nNo API elements detected.\n";
#     }
#     lines = ["## 📚 API Reference\n"];
#     for file, meta in code_meta.items() {
#         lines.append(f"### `{file}`\n");
#         for fn in meta.get("functions", []) {
#             lines.append(f"- **`{fn}`** – _Function description placeholder._");
#         }
#         lines.append("");
#     }
#     return "\n".join(lines);
# }

# impl DocGenie.generate_diagram {
#     return "## 🖼️ System Diagram\n\n```mermaid\ngraph LR\n  main.py --> train_model\n  train_model --> preprocess_data\n```\n";
# }

# # Semantic instruction for LLM
# sem DocGenie.generate_documentation = """
# Generate a complete markdown document with these sections in order:
# 1. Project Overview
# 2. Installation
# 3. Usage
# 4. API Reference
# 5. System Diagram
# Call each rendering tool exactly once.
# Return the full markdown as a single string.
# """;

# node DocGenie(Toolbox) {
#     has final_markdown: str = "";
#     has include_diagrams: bool = true;

#      #  AGENT 1: OverviewAgent
#      def OverviewAgent(readme_summary: str) -> str by llm(
#         role="You are a Documentation Specialist focused on project overviews.",
#         prompt="Summarize the following README content into a clear, engaging 'Project Overview' section for developer docs.",
#         input=readme_summary,
#         output_format="Markdown section starting with '## Project Overview'"
#     );

#     #  AGENT 2: InstallAgent
#     def InstallAgent(file_tree: dict) -> str by llm(
#         role="You are a DevOps Documentation Agent.",
#         prompt="Based on the repository file structure, generate a concise 'Installation' guide in Markdown. "
#                "Check for files like requirements.txt, pyproject.toml, Dockerfile, etc. "
#                "If none found, give a generic instruction.",
#         input=str(file_tree),
#         output_format="Markdown section starting with '## Installation'"
#     );

#      #  AGENT 3: UsageAgent
#      def UsageAgent(file_tree: dict, code_meta: dict) -> str by llm(
#         role="You are a Developer Experience Agent.",
#         prompt="Identify likely entry points (e.g., main.py, app.py) from the file tree and code metadata. "
#                "Generate a 'Usage' section showing how to run the project.",
#         input={"file_tree": file_tree, "code_meta": code_meta},
#         output_format="Markdown section starting with '## Usage'"
#     );

#     #  AGENT 4: ApiDocAgent
#     def ApiDocAgent(code_meta: dict) -> str by llm(
#         role="You are an API Documentation Engineer.",
#         prompt="Generate a detailed API reference from the provided code metadata. "
#                "For each file, list its classes and functions with brief, professional descriptions. "
#                "Use placeholders if descriptions are missing, but keep structure clean.",
#         input=code_meta,
#         output_format="Markdown section starting with '## 📚 API Reference', with subsections per file"
#     );

#      #  AGENT 5: DiagramAgent
#      def DiagramAgent(code_meta: dict) -> str {
#         if not self.include_diagrams or not code_meta {
#             return "";
#         }
            
#         # Using LLM to generate *realistic* Mermaid based on actual structure
#         diagram_spec = llm(
#             role="You are a Software Architect.",
#             prompt="Generate a Mermaid flowchart (graph TD) showing key module relationships based on this code structure. "
#                    "Only include real files and plausible call flows. Output ONLY the Mermaid code block.",
#             input=code_meta,
#             output_format="Raw Mermaid code without markdown fences"
#         );
#         return "## System Diagram\n\n```mermaid\n" + diagram_spec + "\n```\n";
#     }

#     #  COORDINATOR: DocGenie (main)
#     def generate_documentation(
#         readme_summary: str,
#         file_tree: dict,
#         code_meta: dict
#     ) -> str {
#         # Parallel-style execution (simulated sequentially here)
#         overview = self.OverviewAgent(readme_summary);
#         install  = self.InstallAgent(file_tree);
#         usage    = self.UsageAgent(file_tree, code_meta);
#         api_ref  = self.ApiDocAgent(code_meta);
#         diagram  = self.DiagramAgent(code_meta);

#         # Assemble final document
#         full_doc = "\n".join([
#             overview.strip(),
#             install.strip(),
#             usage.strip(),
#             api_ref.strip(),
#             diagram.strip()
#         ]);

#         return full_doc;
#     }

#     # === Entry ability: called by CodeGenius ===
#     can process with CodeGenius entry {
#         md = self.generate_documentation(
#             readme_summary=visitor.readme_context,
#             file_tree=visitor.repo_structure,
#             code_meta=visitor.code_metadata
#         );
#         self.final_markdown = md;
#         visitor.final_docs = md;  # Pass back to supervisor
#     }
# }
