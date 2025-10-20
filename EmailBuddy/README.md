# EmailBuddy — GraphRAG Email Agent

**EmailBuddy** is a sample application that demonstrates how to use **Jac** to build an AI agent capable of navigating a **graph-based email system**.  
Instead of relying on traditional tables or relational databases, this app shows how Object Spatial Representation (OSP) can be used for **graph traversal**, enabling natural and powerful operations like summarizing conversations, retrieving attachments, and exploring communication patterns.

## Overview

Emails form complex networks connecting senders, recipients, CC/BCCs, and threaded conversations over time.  
Modeling these relationships in a graph allows an AI agent (or **walker**) to move intuitively through your email history, following edges that represent relationships or context.

### Graph Structure
The email graph is composed of nodes and edges representing:

- **People**
- **Emails**

The graph only has unidirectional edges representing if you were the sender or recipient of an email:

ex. Amy sends Susanne an email the graph may look like...
```
Amy ++> email ++> Susanne
```

This structure captures the real-world complexity of email interactions far better than flat tables.

## How It Works

### Example: Summarizing a Conversation

**Goal:** “Summarize my conversation with marketing.”

1. **Find the Starting Point:**  
   The AI walker uses **RAG (Retrieval-Augmented Generation)** to locate relevant starting email/person nodes to begin the task.

2. **Traverse the Graph:**  
   The walker explores edges to move between connected emails.  
   It carries its internal **state**, including the current summary and objective.

3. **Build Context and Summarize:**  
   As the walker reaches new email nodes, it reads their content, updates the running summary, and continues traversing until the query has been answered.


## Why Graphs (and Jac) Excel Here

<!-- TODO -->

## What You’ll Learn

- How to **build and deploy an AI walker** in Jac  
- How graph structures simplify **non-linear data traversal**  
- How to **summarize, query, and explore** data through graph reasoning  
- How **RAG techniques** integrate with graph navigation for contextual AI


## Use Cases

- Summarize entire email threads or discussions  
- Identify communication patterns across teams  
- Build smart assistants that understand context-rich data  

## Tutorial Scope

This tutorial is intentionally **simple but practical**:

- Includes a handful of example emails  
- Walks through each concept step-by-step  
- Provides a clear foundation for extending into a full product  


## Future Possibilities

With this framework, developers can expand **EmailBuddy** into:

- A **personalized email summarizer**  
- An **AI-powered inbox assistant**  
- A **corporate communication analytics tool**


## Getting Started

***TODO***
```bash
# Clone the repo
# Install dependencies
# Run the Jac agent
```