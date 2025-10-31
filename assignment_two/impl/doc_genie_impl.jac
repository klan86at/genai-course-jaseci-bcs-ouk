# -------------------------------------------
# Implementation of DocGenie
# -------------------------------------------

impl DocGenie.render_overview {
    return f"##  Project Overview\n\n{readme_summary}\n";
}

impl DocGenie.render_installation {
    has_reqs = "requirements.txt" in str(file_tree);
    if has_reqs:
        return "##  Installation\n\n```bash\npip install -r requirements.txt\n```\n";
    return "##  Installation\n\nRefer to the repository for setup.\n";
}

impl DocGenie.render_usage {
    entry = [f for f in keys(file_tree) if "main" in f];
    if entry:
        return f"##  Usage\n\n```bash\npython {entry[0]}\n```\n";
    return "##  Usage\n\nSee source files for entry points.\n";
}

impl DocGenie.render_api_reference {
    lines = ["## API Reference\n"];
    for file, meta in code_meta.items():
        lines.append(f"### `{file}`\n");
        for fn in meta.get("functions", []):
            lines.append(f"- **`{fn}`** – _Description placeholder._");
    return "\n".join(lines);
}

impl DocGenie.generate_diagram {
    return "## System Diagram\n\n```mermaid\ngraph LR\n  main --> train_model\n  train_model --> preprocess_data\n```\n";
}

sem DocGenie.generate_documentation = """
Generate a complete markdown document with these sections in order:
1. Project Overview
2. Installation
3. Usage
4. API Reference
5. System Diagram (if include_diagrams is true)

Call each rendering tool exactly once.
Do NOT invent content—use only the provided structured data.
Return the full markdown as a single string.
""";