"""Contains all the helper walkers and tool calls."""


import from byllm.llm { Model }
include nodes;

# glob llm = Model(model_name="ollama/llama3.2:latest", verbose=True);

glob llm = Model(model_name="gemini/gemini-2.5-flash", verbose=True);



walker FindRecipientNodes{
    has targets: list[str] = [];
    has persons: list[Person] = [];
    has missing: list[str] = [];

    can start with `root entry {
        self.missing = self.targets;
        visit [-->];
    }

    can search with Person entry {
        
        cleaned_name = normalize(here.name);
        if cleaned_name in self.targets {
            # Track found people, remove from missing list
            self.persons.append(here);
            self.missing = [name for name in self.missing if cleaned_name not in name];
        }
        if len(self.missing) == 0 {
            disengage;
        }
        visit [-->];
    }
}

walker FindSenderNode {
    has target: str;
    has person: Person = None;

    can start with `root entry {
        visit [-->];
        return self.person;
    }

    can search with Person entry {
        if here.name == self.target {
            self.found = True;
            self.person = here;
            disengage;
        }
        visit [-->];
    }    
}

walker FindEmailNode{
    has targets: list[str] = [];
    has emails: list[Email] = [];

    can start with `root entry {
        visit [-->];
    }

    can search with Email entry {   
        if here.body in self.targets {
            self.emails.append(here);
        }
        if len(self.emails) == len(self.targets) {
            disengage;
        }
        visit [-->];
    }
}

def normalize(email: str) -> str{
    if "<" in email{
        return email.split("<")[1].split(">")[0].strip();
    }
    return email.strip();
}

def email_node_to_string(email: Email) -> str{
    output: str = "";
    output += "Subject:\n" + email.subject;
    output += "\nDate\n:" + email.date;
    output += "\n\nBody:\n" + email.body;
    return output;
}


def person_node_to_string(person: Person) -> str{
    output: str = "";
    output += "Name:\n" + person.name;
    return output;
}

# Handles all Agentic selection


obj Response{
    has choice: str;
    has reasoning_for_choice: str;
}

"""
senders: List of people who sent the email
recipients: List of people who received the email
email: Content of the email itself in question
conversation_history: previous prompts and responses


Return:

Choose the initial person to explore on graph with your thought process
choice: <person being explored>, reasoning_for_choice: <reasoning>

OR

If you have an answer to the initial user prompt
choice: "@end@", reasoning_for_choice: <Final response to display to user>
"""
def choose_next_person_node(senders: list[str], recipients: list[str], email: str, conversation_history: list[dict]) -> Response by llm();

"""
person: Person who is being explored
sent: List of emails this person has sent
received: List of emails this person has received
conversation_history: previous prompts and responses

Return:

Choose the initial email to explore on graph with your thought process
choice: <verbatim email subject>, reasoning_for_choice: <reasoning>

OR

If you have an answer to the initial user prompt
choice: "@end@", reasoning_for_choice: <Final response to display to user>
"""
def choose_next_email_node(person: str, sent: list[str], received: list[str], conversation_history: list[dict]) -> Response by llm();


"""
emails: initial emails found with vector search 
conversation_history: previous prompts and responses

Return:

Choose the initial email to explore on graph with your thought process
choice: <verbatim email subject>, reasoning_for_choice: <reasoning>

OR

If you have an answer to the initial user prompt
choice: "@end@", reasoning_for_choice: <Final response to display to user>
"""
def choose_initial_email_node(emails: list[str], conversation_history: list[dict]) -> Response by llm();


"""
Answer the user's initial question with context given.
"""
def respond_to_user(convo_history: dict[str,str]) -> str by llm();