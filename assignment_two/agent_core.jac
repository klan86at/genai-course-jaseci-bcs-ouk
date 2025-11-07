import from dotenv { load_dotenv }

# Base archetype for all worker nodes
node Toolbox {
    # Abstract method: each worker implements its own logic
    def process() -> None abs;

}