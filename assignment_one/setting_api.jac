import from byllm { Model }

glob llm = Model(model_name="groq/llama-3.1-8b-instant");
def write_poem(topic: str) -> str by llm();

with entry {
    poem = write_poem("A serene landscape with domestic animals typical Kenyan farm");
    print(poem);
}