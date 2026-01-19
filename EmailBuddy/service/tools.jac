"""Contains all the helper walkers and tool calls."""


import from byllm.llm { Model }
include service.nodes;
include service.rag;

glob llm = Model(model_name="openai/gpt-5");


walker FindRecipientNodes{
    has targets: list[tuple[str, str]] = [];
    has missing: list[tuple[str, str]] = [];
    has persons: list[Person] = [];

    can start with `root entry {
        self.persons: list[Person] = [];
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
    }    
}

walker FindEmailNode{
    has targets: list[str] = []; # [uuids]
    has emails: list[EmailNode] = [];
    has target_set: set[str] = set();

    can start with `root entry {
        self.target_set = set(self.targets);
        if len(self.target_set) == 0 {
            disengage;
        }

        visit [--> (`?EmailNode)];
    }

    can startPerson with Person entry {
        self.target_set = set(self.targets);

        if len(self.target_set) == 0 {
            disengage;
        }

        for email in [--> (`?EmailNode)]{
            visit email;
        }
    }

    can search with EmailNode entry {
        # Search through all ids for this email, if found track node and pop uuid from search
        if here.email_uuid in self.target_set {
            self.emails.append(here);
            self.target_set.remove(here.email_uuid); 
        }

        # If no more targets exit
        if len(self.target_set) == 0 {
            disengage;
        }
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

def email_node_to_string(email: EmailNode) -> str{
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


walker PrintGraph {
    can start with `root entry {
        print("--- Graph Visualization ---");
        visit [-->];
    }

    can visit_person with Person entry {
        print(f"Person: {here.name} ({here.email})");
        visit [-->];
    }

    can visit_email with EmailNode entry {
        print(f"Email: {here.subject} [{here.email_uuid}]");
    }
}

# Handles all Agentic selection


obj Response{
    has option: str;
    has selection: str;
    has explanation: str;
}

sem Response = "Structured response used by an agentic traversal logic.";
sem Response.option = "A control token defining action: @selected@ (select traversal node), @query@ (phrase for semantic search query), or @end@.";
sem Response.selection = "The chosen email-address, email-uuid, search query, or final response.";
sem Response.explanation = "A short justification for why this decision was made.";


"""
senders: List of people who sent the email
recipients: List of people who received the email
email: Content of the email itself in question
conversation_history: previous prompts and responses
"""
def choose_next_person_node(senders: list[str], recipients: list[str], email: str, conversation_history: list[dict]) -> Response by llm();

"""
person: Person who is being explored
sent: List of emails this person has sent
received: List of emails this person has received
conversation_history: previous prompts and responses
"""
def choose_next_email_node(person: str, sent: list[str], received: list[str], conversation_history: list[dict]) -> Response by llm();


"""
emails: initial emails found with vector search 
conversation_history: previous prompts and responses
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

"""
Summarize relevant part of each option to the initial query not in current conversation history
"""
def summarize(presented_option: list[str], convo_history: list[dict]) -> str by llm();