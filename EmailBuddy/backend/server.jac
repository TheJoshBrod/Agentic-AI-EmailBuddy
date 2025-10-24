"""Contains all the API Endpoints."""

# Python Libraries
import json;
import uuid;

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

            # Generate uuid for email (useful for retrieval later)
            stable_key = f"{msg.get('from','')}-{msg.get('date','')}-{msg.get('subject','')}-{msg.get('body','')}";
            email_uuid = uuid.uuid3(uuid.NAMESPACE_DNS, stable_key);

            # -----------------------
            # - HANDLE EMAIL SENDER -
            # -----------------------
            
            # Extract sender info
            sender_raw = msg.get("from", "");
            if not sender_raw:
                continue;
            response = normalize(sender_raw);
            name = response[0];
            email = response[1]; 

            # Spawn walker to check if sender node already exists
            FindSend = FindSenderNode(target=email);
            root spawn FindSend;

            # Check if sender (person node) found
            sender = FindSend.person;
            if FindSend.person is not None {
                # If it exists set to existing node
                if sender.name == "" and name != "" {
                    sender.name = name;
                }    
            }
            else{
                # else create new node connected to root
                sender = Person(name=name, email=email);
                root ++> sender;            
            }


            # --------------------------
            # - HANDLE EMAIL RECIPIENT -
            # --------------------------

            # Extract recipient information
            recipient_raw = msg.get("to", "");
            if not recipient_raw:
                continue;
            email_list = recipient_raw.split(", ");
            email_list = [normalize(email) for email in email_list];

            # Spawn walker to check if recipient node already exists
            FindRec = FindRecipientNodes(targets=email_list);
            root spawn FindRec;
            found = FindRec.persons;

            # For recipients (person nodes) that don't exit, make them.
            if len(found) != len(email_list) {
                
                missing_emails: list[tuple[str, str]] = FindRec.missing; # list[(name, email_addr), ...]
                for missing in missing_emails {

                    name = missing[0];
                    email = missing[1];

                    recipient = Person(name=name, email=email);
                    root ++> recipient;

                    found.append(recipient);
                }
            }

            # Exported Gmail inboxes don't always provide names, this updates existing email nodes without names 
            name_lookup: dict = {person[1]: person[0] for person in email_list};
            for person_node in found {
                if person_node.name == "" and person_node.email in name_lookup {
                    new_name = name_lookup[person_node.email];
                    if new_name != "" {
                        person_node.name = new_name;
                    }
                }
            }

            # ----------------
            # - HANDLE EMAIL -
            # ----------------

            # Spawn walker to check if email node already exists
            FindEmail = FindEmailNode(targets=[email_uuid]);
            sender spawn FindEmail;
            emails = FindEmail.emails;

            if len(emails) != 0{
                continue;
            }

            # Create new Email node
            email = Email(date=msg["date"], subject=msg["subject"], body=msg["body"], email_uuid=email_uuid);
            root ++> email;

            # Link sender to email
            sender ++> email;

            # Link recipients to email
            for person in found {
                email ++> person;
            }

            # Generate embedding for the email content
            create_email_embedding(msg, email_uuid);
        }
    }
}

walker ask_email {
    has query: str;
    has conversation_history: list[dict] = [];

    obj __specs__ {
        static has auth: bool = False;
    }
    
    
    can handle_email_query(query: str) -> None;

    can handle_query with `root entry{

        # Initialize conversation history
        self.conversation_history.append({"role": "user", "content": self.query});

        # Start email search
        handle_email_query(query);
    }

    can handle_email_node with Email entry {
        
        # Extract sender of email, recipients of email, body/date/subject of email (nodes and str)
        sender: list[Person] = [here <-- (`?Person) ];
        sender_formatted: list[str] = [person_node_to_string(person) for person in sender];

        recipients: list[Person] = [here --> (`?Person)];
        recipients_formatted: list[str] = [person_node_to_string(person) for person in recipients];

        email_formatted: str = email_node_to_string(here);


        # Merges people into one list for later search
        search_pool: list[Person] = sender + recipients;


        # Choose next person node to explore
        response = choose_next_person_node(str(sender_formatted), str(recipients_formatted), email_formatted, self.conversation_history);

        # Update findings to conversation history
        self.conversation_history.append({"type": "found-people", "content": f"Sender of current email: {sender_formatted}\n\n\nRecipient of current email: {recipients_formatted}"});
        self.conversation_history.append({"type": "selected-person", "content": str(response.selection)});
        self.conversation_history.append({"role": "system", "content": response.explanation});

        # Handle next actions:
        if response.option == "@end@" {
            # If got answer from initial search, respond with answer
            report {"response": respond_to_user(self.conversation_history), "source": []};            
        }
        else if response.option == "@selected@" {
            # Select next person based on email address
            selected_person_node: Person = None;
            for person in search_pool {
                if(person.email == response.selection){
                    selected_person_node = person;
                    break;
                }
            }

            # if selected person not found, retry 4 times (5 total)
            counter: int = 0;
            while selected_person_node is None and counter < 4 {
                self.conversation_history.append({"type": "meta-error", "content": "email address did not verbatim match try again"})
                response = choose_next_person_node(str(sender_formatted), str(recipients_formatted), email_formatted, self.conversation_history);
                self.conversation_history.append({"type": "selected", "content": str(response.selection)});
                self.conversation_history.append({"role": "system", "content": response.explanation});
                for person in search_pool {
                    if(person.email == response.selection){
                        selected_person_node = person;
                        break;
                    }
                }
                counter += 1;
            }

            # Exits if still not found
            if selected_person_node is None {
                report {"response": "Error during email search please try again", "source": []};
            }
            
            # Goto next Person             
            visit selected_person_node;
        }
        else if (response.option == "@query@"){
            # Queries other emails using fuzzy vector search
            handle_email_query(response.selection);     
        }
        else{
            # This should never happen.
            report {"response": "Error during email search please try again", "source": []};
        }
    }


    can handle_person_node with Person entry {
        
        # Extract relevant info about current node to share to agent        
        sent: list[Email] = [here --> (`?Email)];
        sent_formatted: list[str] = [email_node_to_string(email) for email in sent];
        
        received: list[Email] = [here <-- (`?Email)];
        received_formatted: list[str] = [email_node_to_string(email) for email in received];
        
        search_pool: list[Email] = sent + received; 

        person_formatted: str = person_node_to_string(here);

        response = choose_next_email_node(person_formatted, str(sent_formatted), str(received_formatted), self.conversation_history);

        # Update conversation history:
        self.conversation_history.append({"type": "found-email", "content": f"Sent Emails: {sent_formatted}\n\n\nReceived: {received_formatted}"});
        self.conversation_history.append({"type": "selected", "content": str(response.selection)});
        self.conversation_history.append({"role": "system", "content": response.explanation});

        if response.option == "@end@" {
            report {"response": respond_to_user(self.conversation_history), "source": []};
        }
        else if response.option == "@query@" {
            handle_email_query(response.selection);     
        }
        else if response.option == "@selected@" {
            
            # Select next email based on date
            selected_email_node: Email = None;
            for email in search_pool {
                if(email.email_uuid == response.selection){
                    selected_email_node = email;
                    break;
                }
            }

            # If next email not found, try again 4 more times (5 total)
            counter: int = 0;
            while selected_email_node is None and counter < 4 {
                self.conversation_history.append({"type": "meta-error", "content": "email uuid did not verbatim match try again"})
                response = choose_next_email_node(person_formatted, str(sent_formatted), str(received_formatted), self.conversation_history);
                self.conversation_history.append({"type": "selected", "content": str(response.selection)});
                self.conversation_history.append({"role": "system", "content": response.explanation});
                for email in search_pool {
                    if(email.email_uuid == response.selection){
                        selected_email_node = email;
                        break;
                    }
                }
                counter += 1;
            }

            # Exits if still not found
            if selected_email_node is None {
                report {"response": "Error during email search please try again", "source": []};
            }
            
            # Goto next Email 
            visit selected_email_node;
        }
        else{
            # This should never happen.
            report {"response": "Error during email search please try again", "source": []};
        }
        
    }

}