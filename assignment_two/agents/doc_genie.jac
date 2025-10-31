# import form impl { doc_genie_impl }

node DocGenie(Toolbox) {
    has final_markdown: str = "";
    has include_diagrams: bool = true;

     #  AGENT 1: OverviewAgent
     def OverviewAgent(readme_summary: str) -> str by llm(
        role="You are a Documentation Specialist focused on project overviews.",
        prompt="Summarize the following README content into a clear, engaging 'Project Overview' section for developer docs.",
        input=readme_summary,
        output_format="Markdown section starting with '## Project Overview'"
    );

    #  AGENT 2: InstallAgent
    def InstallAgent(file_tree: dict) -> str by llm(
        role="You are a DevOps Documentation Agent.",
        prompt="Based on the repository file structure, generate a concise 'Installation' guide in Markdown. "
               "Check for files like requirements.txt, pyproject.toml, Dockerfile, etc. "
               "If none found, give a generic instruction.",
        input=str(file_tree),
        output_format="Markdown section starting with '## Installation'"
    );

     #  AGENT 3: UsageAgent
     def UsageAgent(file_tree: dict, code_meta: dict) -> str by llm(
        role="You are a Developer Experience Agent.",
        prompt="Identify likely entry points (e.g., main.py, app.py) from the file tree and code metadata. "
               "Generate a 'Usage' section showing how to run the project.",
        input={"file_tree": file_tree, "code_meta": code_meta},
        output_format="Markdown section starting with '## Usage'"
    );

    #  AGENT 4: ApiDocAgent
    def ApiDocAgent(code_meta: dict) -> str by llm(
        role="You are an API Documentation Engineer.",
        prompt="Generate a detailed API reference from the provided code metadata. "
               "For each file, list its classes and functions with brief, professional descriptions. "
               "Use placeholders if descriptions are missing, but keep structure clean.",
        input=code_meta,
        output_format="Markdown section starting with '## 📚 API Reference', with subsections per file"
    );

     #  AGENT 5: DiagramAgent
     def DiagramAgent(code_meta: dict) -> str {
        if not self.include_diagrams or not code_meta {
            return "";
        }
            
        # Using LLM to generate *realistic* Mermaid based on actual structure
        diagram_spec = llm(
            role="You are a Software Architect.",
            prompt="Generate a Mermaid flowchart (graph TD) showing key module relationships based on this code structure. "
                   "Only include real files and plausible call flows. Output ONLY the Mermaid code block.",
            input=code_meta,
            output_format="Raw Mermaid code without markdown fences"
        );
        return "## System Diagram\n\n```mermaid\n" + diagram_spec + "\n```\n";
    }

    #  COORDINATOR: DocGenie (main)
    def generate_documentation(
        readme_summary: str,
        file_tree: dict,
        code_meta: dict
    ) -> str {
        # Parallel-style execution (simulated sequentially here)
        overview = self.OverviewAgent(readme_summary);
        install  = self.InstallAgent(file_tree);
        usage    = self.UsageAgent(file_tree, code_meta);
        api_ref  = self.ApiDocAgent(code_meta);
        diagram  = self.DiagramAgent(code_meta);

        # Assemble final document
        full_doc = "\n".join([
            overview.strip(),
            install.strip(),
            usage.strip(),
            api_ref.strip(),
            diagram.strip()
        ]);

        return full_doc;
    }

    # === Entry ability: called by CodeGenius ===
    can process with CodeGenius entry {
        md = self.generate_documentation(
            readme_summary=visitor.readme_context,
            file_tree=visitor.repo_structure,
            code_meta=visitor.code_metadata
        );
        self.final_markdown = md;
        visitor.final_docs = md;  # Pass back to supervisor
    }
}
