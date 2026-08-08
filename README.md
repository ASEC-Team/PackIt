# **PackIt**

PackIt is a highly flexible, schema-based serialization framework engineered for long-term data persistence and backward compatibility. Designed to sanitize and compress data efficiently, PackIt supports extensible serialization **Modes** and **Engines**, allowing developers to build custom implementations tailored to their specific technical requirements.

This project is currently in **Beta**. Please reach out to contact us regarding any bugs you encounter, or if you would like to collaborate on developing new engines and features!

### **Performance & Compression**
PackIt is highly optimized for data efficiency, delivering an average **65% reduction in data size** compared to standard JSON encoding.

When paired with Roblox's native buffer compression it scales even further achieving **up to 90% size reduction** against JSON.

This drastic footprint reduction minimizes bandwidth consumption, making it an ideal choice for both high-frequency network replication and storage-capped data persistence.

### **Extensibility & Community Contributions**
The framework is engineered from the ground up for high extensibility, allowing developers to scale its core capabilities effortlessly. Because the architecture decouples structural design from the underlying serialization logic, the community can easily implement and integrate custom **Engines**, **Modes**, and specialized **Data Types**. This ensures that PackIt can adapt to unique project demands and evolve alongside community-driven innovations.

---

## Documentation
Learn more about this at: [PackIt Docs](https://asec-team.github.io/PackIt/)
