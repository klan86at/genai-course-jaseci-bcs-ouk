import from byllm { model }

glob llm = Model(model_name="openai/gpt-oss-20b");
def write_poem(topic: str) -> str by llm();

with entry {
    poem = write_poem("A serene landscape with domestic animals typical Kenyan farm");
    print(poem);
}