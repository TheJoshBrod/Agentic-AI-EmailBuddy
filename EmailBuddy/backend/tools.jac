"""Contains all the helper walkers and tool calls."""


import from byllm.llm { Model };
include nodes;

# glob llm = Model(model_name="ollama/llama3.2:latest", verbose=True);

# glob llm = Model(model_name="gemini/gemini-2.5-flash", verbose=True);

glob llm = Model(model_name="openai/gpt-5", verbose=True);


walker FindRecipientNodes{
    has targets: list[tuple[str, str]] = [];
    has missing: list[tuple[str, str]] = [];
    has persons: list[Person] = [];

    can start with `root entry {
        self.missing = self.targets;
        visit [-->];
    }

    can search with Person entry {
        
        # If node has an email in targets update tracker
        for pair in self.targets {
            if here.email == pair[1] {
                self.persons.append(here);
                self.missing.remove(pair);
                break;
            }
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
        if here.email == self.target {
            self.person = here;
            disengage;
        }
        visit [-->];
    }    
}

walker FindEmailNode{
    has targets: list[str] = []; # [uuids]
    has emails: list[Email] = [];
    has target_set: set[str] = {};

    can start with `root entry {
        self.target_set = set(self.targets);

        if len(self.target_set) == 0 {
            disengage;
        }

        visit [--> (`?Email)];
    }


    can start with `Person entry {
        self.target_set = set(self.targets);

        if len(self.target_set) == 0 {
            disengage;
        }

        visit [--> (`?Email)];
    }

    can search with Email entry {

        # Search through all ids for this email, if found track node and pop uuid from search
        if here.email_uuid in self.target_set {
            self.emails.append(here);
            self.target_set.remove(here.email_uuid); 
        }

        # If no more targets exit
        if len(self.target_set) == 0 {
            disengage;
        }
        
        # Go to next Email node if 
        visit [-->];
    }
}

def normalize(email: str) -> tuple[str, str] {
    name: str = "";
    addr: str = "";

    if "<" in email {
        parts: list[str] = email.split("<");
        name = parts[0].strip();
        addr = parts[1].split(">")[0].strip();
    } else {
        addr = email.strip();
    }

    return (name, addr);
}

def email_node_to_string(email: Email) -> str{
    output: str = "";
    output += "Subject:\n" + email.subject;
    output += "\nDate\n:" + email.date;
    output += "\n\nBody:\n" + email.body;
    output += "\n\uuid:\n" + email.email_uuid;
    return output;
}

def person_node_to_string(person: Person) -> str{
    output: str = "";
    output += "Name:\n" + person.name;
    return output;
}

# Handles all Agentic selection


obj Response{
    has option: str;
    has selection: str;
    has explanation: str;
}

"""
senders: List of people who sent the email
recipients: List of people who received the email
email: Content of the email itself in question
conversation_history: previous prompts and responses


Return:

If you have a person to select:
option: "@selected@", selection: <email address of person>, explanation: <reasoning for selection>

Use this to fuzzy search ALL emails instead of the selecting one provided:
option: "@query@", selection: <phrase to be vectorized>, explanation: <reasoning for new search>

If you have an answer to the initial user prompt
option: "@end@", selection: <Answer you have concluded from options/conversation history>, explanation: <Why you stopped here>
"""
def choose_next_person_node(senders: list[str], recipients: list[str], email: str, conversation_history: list[dict]) -> Response by llm();

"""
person: Person who is being explored
sent: List of emails this person has sent
received: List of emails this person has received
conversation_history: previous prompts and responses

Return:

If you have an email to select:
option: "@selected@", selection: <verbatim email uuid>, explanation: <reasoning for selection>

Use this to fuzzy search ALL emails instead of the selecting one provided:
option: "@query@", selection: <phrase to be vectorized>, explanation: <reasoning for new search>

If you have an answer to the initial user prompt
option: "@end@", selection: <Answer you have concluded from options/conversation history>, explanation: <Why you stopped here>
"""
def choose_next_email_node(person: str, sent: list[str], received: list[str], conversation_history: list[dict]) -> Response by llm();


"""
emails: initial emails found with vector search 
conversation_history: previous prompts and responses

Return:

Choose the initial email to explore on graph with your thought process
option: "@selected@", selection <verbatim email uuid>, explanation: <reasoning for selection>

Use this to fuzzy search ALL emails instead of the selecting one provided:
option: "@query@", selection: <phrase to be vectorized>, explanation: <reasoning for new search>

If you have an answer to the initial user prompt
option: "@end@", selection: <Answer you have concluded from options/conversation history>, explanation: <Why you stopped here>
"""
def choose_initial_email_node(emails: list[str], conversation_history: list[dict]) -> Response by llm();


"""
Answer the user's initial question with context given.
"""
def respond_to_user(convo_history: list[dict]) -> str by llm();

"""
You failed to extract the identifier, try again.
"""
def retry_extract_identifier(convo_history: list[dict]) -> Response by llm();