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

        self.conversation_history.append({"type": "found-emails", "content": initial_emails_formatted});
        self.conversation_history.append({"type": "tool-call-response", "content": str(response)});
        self.conversation_history.append({"role": "user", "content": response.reasoning_for_choice});

        if (response.choice != "@end@"){
            initial_email: Email;
            for email in initial_emails {
                if(response.choice in email.subject){
                    initial_email = email;
                    break;
                }
            }
            visit initial_email;
        }
        
        report {"response": respond_to_user(self.conversation_history), "source": []};
    }

    can handle_email_node with Email entry {
        sender: list[Person] = [<-- (`?Person) ];
        sender_formatted: list[str] = [person_node_to_string(person) for person in sender];

        recipients: list[Person] = [here --> (`?Person)];
        recipients_formatted: list[str] = [person_node_to_string(person) for person in recipients];
        
        email_formatted: str = email_node_to_string(here);

        response = choose_next_person_node(str(sender_formatted), str(recipients_formatted), email_formatted, self.conversation_history);

        self.conversation_history.append({"type": "found-people", "content": f"Sender of current email: {sender_formatted}\n\n\nRecipient of current email: {recipients_formatted}"});
        self.conversation_history.append({"type": "selected-person", "content": str(response)});
        self.conversation_history.append({"role": "system", "content": response.reasoning_for_choice});
        
        if response.choice == "@end@" {
            report {"response": respond_to_user(self.conversation_history), "source": []};
        }


        selected_person_node: Person;
        for person in sent {
            if(person.name == response.choice){
                selected_person_node = person;
                break;
            }
        }
        for person in received {
            if(person.name == response.choice){
                selected_person_node = person;
                break;
            }
        }

        visit selected_person_node;

    }


    can handle_person_node with Person entry {
        
        # Extract relevant info about current node to share to agent        
        sent: list[Email] = [<-- (`?Email) ];
        sent_formatted: list[str] = [email_node_to_string(email) for email in sent];
        
        received: list[Email] = [here --> (`?Email)];
        received_formatted: list[str] = [email_node_to_string(email) for email in received];
        
        person_formatted: str = person_node_to_string(here);

        response = choose_next_person_node(person_formatted, str(sent_formatted), str(received_formatted), self.conversation_history);

        # Update conversation history:
        self.conversation_history.append({"type": "found-email", "content": f"Sent Emails: {sent_formatted}\n\n\nReceived: {received_formatted}"});
        self.conversation_history.append({"type": "tool-call", "content": str(response)});
        self.conversation_history.append({"role": "system", "content": response.reasoning_for_choice});

        # If no choice selected, disengage (or report?)
        if response.choice == "@end@" {
            report {"response": respond_to_user(self.conversation_history), "source": []};
        }
        
        
        # Visit next Email 
        selected_email_node: Email;
        for email in sent {
            if(email.subject in response.choice){
                selected_email_node = email;
                break;
            }
        }
        for person in received {
            if(email.subject == response.choice){
                selected_email_node = email;
                break;
            }
        }

        visit selected_email_node;
    }

}