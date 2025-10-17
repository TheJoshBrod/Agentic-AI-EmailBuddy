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

        # for child in [root -->] {
        #     del child;
        # }

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
        
        response = choose_next_email_node(str(initial_emails_formatted), self.conversation_history);
        print(f"\n\n\n\n{len(self.conversation_history)}");
        print(response.reasoning_for_choice);
        print(response.choice);
        
        self.conversation_history.append({"role": "user", "content": response[1]});
        if (response[0] != "@end@"){
            initial_email: Email;
            for email in initial_emails {
                if(response[0] == email.body){
                    initial_email = email;
                    break;
                }
            }
            visit initial_email;
        }
        
        report {"response": self.conversation_history[-1]["content"], "source": []};
    }

    can handle_email_node with Email entry {
        sender: list[Person] = [<--];
        sender_formatted: list[str] = [person_node_to_string(person) for email in sender];

        recipients: list[Person] = [-->];
        recipients_formatted: list[str] = [person_node_to_string(person) for person in recipients];
        
        email_formatted: str = email_node_to_string(here);


        # TODO: Do i need to put the sender, recipients found in convo history?
        # self.conversation_history.append({"type": "tool-call", }); 
        
        response = choose_next_person_node(str(sender_formatted), str(recipients_formatted), email_formatted, self.conversation_history);
        print(f"\n\n\n\n{len(self.conversation_history)}");
        print(response.reasoning_for_choice);
        print(response.choice);
        self.conversation_history.append({"role": "system", "content": response[1]});
        if response[0] == "@end@" {
            disengage;
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
        
        sent: list[Email] = [<--];
        sent_formatted: list[str] = [email_node_to_string(email) for email in sent];
        
        received: list[Email] = [-->];
        received_formatted: list[str] = [email_node_to_string(email) for email in received];
        
        person_formatted: str = person_node_to_string(here);

        # TODO: Do i need to put the sent, received found in convo history?
        # self.conversation_history.append({"type": "tool-call", }); 
        
        response = choose_next_person_node(person_formatted, str(sent_formatted), str(received_formatted), self.conversation_history);
        self.conversation_history.append({"role": "system", "content": response[1]});

        print(f"\n\n\n\n{len(self.conversation_history)}");
        print(response.reasoning_for_choice);
        print(response.choice);

        # If no choice selected, disengage (or report?)
        if response.choice == "@end@" {
            disengage;
        }
        
        
        # Visit next Email 
        selected_email_node: Email;
        for email in sent {
            if(email.body == response.choice){
                selected_email_node = email;
                break;
            }
        }
        for person in received {
            if(email.body == response.choice){
                selected_email_node = email;
                break;
            }
        }

        visit selected_email_node;
    }

}