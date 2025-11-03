# agent_core.jac — Core archetypes for CodeGenius pipeline
import from dotenv { load_dotenv }

# Base archetype for all worker nodes (enables consistent interface)
node Toolbox {
    # Abstract method: each worker implements its own logic
    def process() -> None abs;

    # Standard entry point for CodeGenius walker
    can execute with CodeGenius entry {
        self.process();
    }
}