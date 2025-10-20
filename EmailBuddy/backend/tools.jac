"""Contains all the helper walkers and tool calls."""


import from byllm.llm { Model }
include nodes;
include rag;

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

# Handles all Agentic selection


obj Response{
    has option: str;
    has value: str;
    has reasoning_for_choice: str;
}

"""
senders: List of people who sent the email
recipients: List of people who received the email
email: Content of the email itself in question
conversation_history: previous prompts and responses


Return:

Choose the initial person to explore on graph with your thought process
option: "@selected@", value: <person being explored>, reasoning_for_choice: <reasoning>

OR

If you have an answer to the initial user prompt
option: "@end@", value: "", reasoning_for_choice: <Final response to display to user>

OR 

If you REALLY feel you are at a deadend and want new search space (only do this as a last resort)
option: "@query@", value: <keywords>, reasoning_for_choice: <Why you need a new search space>
"""
def choose_next_person_node(senders: list[str], recipients: list[str], email: str, conversation_history: list[dict]) -> Response by llm();

"""
person: Person who is being explored
sent: List of emails this person has sent
received: List of emails this person has received
conversation_history: previous prompts and responses

Return:

Choose the initial email to explore on graph with your thought process
option: "@select@", value: <verbatim email subject>, reasoning_for_choice: <reasoning>

OR

If you have an answer to the initial user prompt
option: "@end@", value: "", reasoning_for_choice: <Final response to display to user>

OR 

If you REALLY feel you are at a deadend and want new search space (only do this as a last resort)
option: "@query@", value: <keywords> reasoning_for_choice: <query to use in vector search for new emails>
"""
def choose_next_email_node(person: str, sent: list[str], received: list[str], conversation_history: list[dict]) -> Response by llm();


"""
emails: initial emails found with vector search 
conversation_history: previous prompts and responses

Return:

Choose the initial email to explore on graph with your thought process
option: "@selected@", value: <verbatim email subject>, reasoning_for_choice: <reasoning>

OR

If you have an answer to the initial user prompt
option: "@end@", value: "", reasoning_for_choice: <Final response to display to user>

OR 

If you REALLY feel you are at a deadend and want new search space (only do this as a last resort)
option: "@query@", value: <keywords>, reasoning_for_choice: <query to use in vector search for new emails>
"""
def choose_initial_email_node(emails: list[str], conversation_history: list[dict]) -> Response by llm();


"""
Answer the user's initial question with context given.
"""
def respond_to_user(convo_history: dict[str,str]) -> str by llm();

"""
Compresses the choice reasoning and options to choose from to one string that will be added to convo history
"""
def summarize(convo_history: dict[str,str], choice: str, reasoning: str, options_to_choose_from: str) -> str by llm();

def expand_query(response: Response, conversation_history: dict[str, str]) -> tuple[Email, dict[str, str]]{
    emails: list[Emails];
    while response.option == "@query@" {
        starting_emails = find_email_body(response.value);
        FindEmails = FindEmailNode(targets=starting_emails);
        root spawn FindEmails;
        emails = FindEmails.emails;
        initial_emails_formatted = [email_node_to_string(email) for email in emails];
        summary = summarize(
            convo_history          = conversation_history,
            choice                 = str(response),
            reasoning              = response.reasoning_for_choice,
            options_to_choose_from = f"Emails found: {initial_emails_formatted}"
            );
        conversation_history.append({"role": "system", "content": summary});
        response = choose_initial_email_node(str(initial_emails_formatted), conversation_history);
    }
    best_email = pick_best_email(emails, response.value);

    return [best_email, conversation_history];
}
    