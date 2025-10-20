"""Contains all the API Endpoints."""

# Python Libraries
import json;

# Jac Files
include tools;
include nodes;
include rag;



walker upload_emails{
    has raw_emails: list;

    obj __specs__ {
        static has auth: bool = False;
    }

    can upload_email with `root entry{

        for child in [root -->] {
            del child;
        }

        emails: list = self.raw_emails;
        for msg in emails {

            # Spawn walker to check if sender node already exists
            # If it exists set to existing node
            # else create new node connected to root
            sender_email = normalize(msg["from"]);
            FindSend = FindSenderNode(target=sender_email);
            sender = root spawn FindSend;
            if FindSend.person is None {
                sender = Person(name=sender_email);
                root ++> sender;
            }
            else{
                sender = FindSend.person;
            }

            # Spawn walker to check if recipient node already exists
            # If it exists set to existing node
            # else create new node connected to root
            email_list = msg["to"].split(", ");
            email_list = [normalize(name) for name in email_list];

            FindRec = FindRecipientNodes(targets=email_list);
            root spawn FindRec;

            found = FindRec.persons;
            if len(found) != len(email_list) {
                missing_emails = FindRec.missing;
                for email in missing_emails {
                    recipient = Person(name=email);
                    root ++> recipient;
                    found.append(recipient);
                }
            }


            # Always create a new email node if uploaded
            email = Email(date=msg["date"], subject=msg["subject"], body=msg["body"]);
            root ++> email;
            sender ++> email;
            for person in found {
                email ++> person;
            }
            create_email_embedding(msg);
        }
    }
}

walker ask_email {
    has query: str;
    has conversation_history: list[dict] = [];

    obj __specs__ {
        static has auth: bool = False;
    }

    can handle_query with `root entry{
        self.conversation_history.append({"role": "user", "content": self.query});

        starting_emails: list[str] = find_email_body(self.query);
        FindEmails = FindEmailNode(targets=starting_emails);
        root spawn FindEmails;

        initial_emails: list[Email] = FindEmails.emails;
        initial_emails_formatted: list[str] = [email_node_to_string(email) for email in initial_emails];
        
        response = choose_initial_email_node(str(initial_emails_formatted), self.conversation_history);

        summary = summarize(
            convo_history           = self.conversation_history,
            choice                 = str(response),
            reasoning              = response.reasoning_for_choice,
            options_to_choose_from = initial_emails_formatted
            );
        self.conversation_history.append({"role": "system", "content": summary});

        if (response.option == "@end@"){
            report {"response": respond_to_user(self.conversation_history), "source": []};
        }
d
        # Lets walker traverse new search space 
        if (response.option == "@query@"){
            temp = expand_query(response, self.conversation_history);
            best_email = temp[0];
            self.conversation_history = temp[1];
            visit best_email;
        }
       
        # Select best initial email to traverse
        initial_email: Email = pick_best_email(initial_emails, response.value);
        visit initial_email;
        
    }

    can handle_email_node with Email entry {
        """When an Email node is entered, have LLM decide which person to expand.""";

        # Extract relevant info about current node to share to agent
        sender: list[Person] = [<-- (`?Person) ];
        sender_formatted: list[str] = [person_node_to_string(person) for person in sender];
        recipients: list[Person] = [here --> (`?Person)];
        recipients_formatted: list[str] = [person_node_to_string(person) for person in recipients];
        email_formatted: str = email_node_to_string(here);

        # Have agent choose next person
        response = choose_next_person_node(str(sender_formatted), str(recipients_formatted), email_formatted, self.conversation_history);

        # Update conversation history
        summary = summarize(
            convo_history           = self.conversation_history,
            choice                 = str(response),
            reasoning              = response.reasoning_for_choice,
            options_to_choose_from = f"Sender of current email: {sender_formatted}\n\n\nRecipient of current email: {recipients_formatted}"
            );
        self.conversation_history.append({"role": "system", "content": summary});

        # Check if query found answer
        if response.option == "@end@" {
            report {"response": respond_to_user(self.conversation_history), "source": []};
        }

        # Lets walker traverse new search space of new emails
        if (response.option == "@query@"){
            temp = expand_query(response, self.conversation_history);
            best_email = temp[0];
            self.conversation_history = temp[1];
            visit best_email;
        }

        # Find next person to explore
        selected_person_node: Person;
        for person in sender {
            print(f"\t- {person.name}");
            if(person.name == response.value){
                selected_person_node = person;
                break;
            }
        }
        for person in recipients {
            print(f"\t- {person.name}");
            if(person.name == response.value){
                selected_person_node = person;
                break;
            }
        }

        # Traverse to next person
        visit selected_person_node;
    }


    can handle_person_node with Person entry {
        """When a Person node is entered, have LLM decide which email to expand.""";

        # Extract relevant info about current node to share to agent        
        sent: list[Email] = [<-- (`?Email) ];
        sent_formatted: list[str] = [email_node_to_string(email) for email in sent];
        received: list[Email] = [here --> (`?Email)];
        received_formatted: list[str] = [email_node_to_string(email) for email in received];
        person_formatted: str = person_node_to_string(here);

        # Have agent choose next email
        response = choose_next_email_node(person_formatted, str(sent_formatted), str(received_formatted), self.conversation_history);

        # Update conversation history:
        summary = summarize(
            convo_history          = self.conversation_history,
            choice                 = str(response),
            reasoning              = response.reasoning_for_choice,
            options_to_choose_from = f"Sent Emails: {sent_formatted}\n\n\nReceived: {received_formatted}"
            );
        self.conversation_history.append({"role": "system", "content": summary});

        # If no choice selected, disengage (or report?)
        if response.option == "@end@" {
            report {"response": respond_to_user(self.conversation_history), "source": []};
        }
        
        # Lets walker traverse new search space 
        if (response.option == "@query@"){
            temp = expand_query(response, self.conversation_history);
            best_email = temp[0];
            self.conversation_history = temp[1];
            visit best_email;
        }

        # Visit next Email 
        selected_email_node: Email = pick_best_email(received + sent, response.value);

        # Traverse to next email
        visit selected_email_node;
    }

}