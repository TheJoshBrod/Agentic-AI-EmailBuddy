"""Contains all the API Endpoints."""

# Python Libraries
import json;
import uuid;
import typing;

# Jac Files
include tools;
include nodes;
include rag;
include prompts;
include jaclens;

glob conversation_history: list[dict] = [];

walker upload_emails{
    has raw_emails: list;

    obj __specs__ {
        static has auth: bool = False;
    }

    can upload_email with `root entry{
        for msg in emails {

            # Generate uuid for email (useful for retrieval later)
            stable_key: str = f"{msg.get('from','')}-{msg.get('date','')}-{msg.get('subject','')}-{msg.get('body','')}";
            email_uuid = str(uuid.uuid3(uuid.NAMESPACE_DNS, stable_key));
            with open("file.txt", "a") as f{
                f.write(email_uuid + "\t" + stable_key + "\n");
            }
            # -----------------------
            # - HANDLE EMAIL SENDER -
            # -----------------------
            
            # Extract sender info
            sender_raw: str = msg.get("from", "");
            if not sender_raw{
                continue;
            }
            response = normalize(sender_raw);
            name = response[0];
            sender_email = response[1]; 

            # Spawn walker to check if sender node already exists
            FindSend = FindSenderNode(target=sender_email);
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
                sender = Person(name=name, email=sender_email);
                root ++> sender;            
            }


            # --------------------------
            # - HANDLE EMAIL RECIPIENT -
            # --------------------------

            # Extract recipient information
            recipient_raw = msg.get("to", "");
            if not recipient_raw{
                continue;
            }
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
            email = EmailNode(sender=sender_raw, recipients=recipient_raw, date=msg["date"], subject=msg["subject"], body=msg["body"], email_uuid=email_uuid);
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

    obj __specs__ {
        static has auth: bool = False;
    }

    def handle_email_query(query: str) -> None {
        # Initialized vars
        initial_emails: list[EmailNode] = [];
        option: str = "@query@";

        # Loops until finds satisfiable email to explore
        query_counter: int = 0;
        while option == "@query@" and query_counter < 4 {

            # Prevents infinite looping
            query_counter += 1;
            
            # Get starting nodes of emails to explore
            starting_emails: tuple[str] = find_emails(query);
            uuids: list[str] = [email[0] for email in starting_emails];
            FindEmails = FindEmailNode(targets=uuids);
            root spawn FindEmails;

            # Choose which email to travel to
            initial_emails = FindEmails.emails;
            initial_emails_formatted: list[str] = [email_node_to_string(email) for email in initial_emails];

            # Update findings to conversation history
            conversation_history.append({
                "type": "found-emails", 
                "content": summarize(initial_emails_formatted, conversation_history)
            });

            response = choose_initial_email_node(str(initial_emails_formatted), conversation_history);

            # Log the agent's choice and reasoning
            conversation_history.append({
                "type": "agent-choice",
                "content": f"Based on the found emails, I will proceed with option '{response.option}'. My selection is '{response.selection}' because: {response.explanation}"
            });

            # Extract relevant information
            query = response.selection;
            option = response.option;
        }
        if (response.option == "@end@"){
            # If got answer from initial search, respond with answer
            # TODO: Separate answer function?
            return respond_to_user(conversation_history);            
        }
        elif response.option == "@selected@" or query_counter == 4 {

            # Select next email based on uuid
            selected_email_node: EmailNode = None;
            for email in initial_emails {
                if(email.email_uuid == response.selection){
                    selected_email_node = email;
                    break;
                }
            }

            # If next email not found, try again 4 more times (5 total)
            selected_counter: int = 0;
            while selected_email_node is None and selected_counter < 4 {
                conversation_history.append({"type": "meta-error", "content": "Email UUID did not verbatim match. Retrying selection."});
                response = retry_extract_identifier(conversation_history);

                conversation_history.append({
                    "type": "agent-retry-choice", 
                    "content": f"My new selection is '{response.selection}' because: {response.explanation}"
                });
                for email in initial_emails {
                    if(email.email_uuid == response.selection){
                        selected_email_node = email;
                        break;
                    }
                }
                selected_counter += 1;
            }

            # Exits if still not found
            if selected_email_node is None {
                return "Error during email search please try again";
            }
            
            # Goto next Email 
            return selected_email_node;
        }
        else{
            # This should never happen.
            return "Error during email search please try again";
        }
    }


    can handle_query with `root entry{

        # Initialize conversation history
        conversation_history.append({"role": "system_prompt", "content": sys_prompt});
        conversation_history.append({"role": "user", "content": self.query});

        # Start email search
        value = self.handle_email_query(self.query);
        if type(value) == str {
            report {"response": value, "source": []};
        }
        elif type(value) == EmailNode {
            visit value;
        }
        else {
            report {"response": "Error", "source": []};
        }
    }

    can handle_email_node with EmailNode entry {
        
        # Extract sender of email, recipients of email, body/date/subject of email (nodes and str)
        sender: list[Person] = [here <-- (`?Person) ];
        sender_formatted: list[str] = [person_node_to_string(person) for person in sender];

        recipients: list[Person] = [here --> (`?Person)];
        recipients_formatted: list[str] = [person_node_to_string(person) for person in recipients];

        email_formatted: str = email_node_to_string(here);


        # Merges people into one list for later search
        search_pool: list[Person] = sender + recipients;

        conversation_history.append({
            "type": "found-people-at-email", 
            "content": f"At email {email_formatted}. Found sender: {str(sender_formatted)} and recipients: {str(recipients_formatted)}."
        });


        # Choose next person node to explore
        response = choose_next_person_node(str(sender_formatted), str(recipients_formatted), email_formatted, conversation_history);

        # Update findings to conversation history
        conversation_history.append({
            "type": "agent-choice", 
            "content": f"I am acting on '{response.option}'. I picked '{response.selection}' because: {response.explanation}"
        });

        # Handle next actions:
        if response.option == "@end@" {
            # If got answer from initial search, respond with answer
            report {"response": respond_to_user(conversation_history), "source": []};            
        }
        elif response.option == "@selected@" {
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
                conversation_history.append({"type": "meta-error", "content": "Email address did not verbatim match. Retrying selection."});
                response = choose_next_person_node(str(sender_formatted), str(recipients_formatted), email_formatted, conversation_history);        
                conversation_history.append({
                    "type": "agent-retry-choice", 
                    "content": f"I am acting on '{response.option}'. My new selection is '{response.selection}' because: {response.explanation}"
                });
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
        elif (response.option == "@query@"){
            # Queries other emails using fuzzy vector search
            value = self.handle_email_query(response.selection);
            if type(value) == str {
                report {"response": value, "source": []};
            }
            else{
                visit value;
            } 
        }
        else{
            # This should never happen.
            report {"response": "Error during email search please try again", "source": []};
        }
    }


    can handle_person_node with Person entry {
        
        # Extract relevant info about current node to share to agent        
        sent: list[EmailNode] = [here --> (`?EmailNode)];
        sent_formatted: list[str] = [email_node_to_string(email) for email in sent];
        
        received: list[EmailNode] = [here <-- (`?EmailNode)];
        received_formatted: list[str] = [email_node_to_string(email) for email in received];
        
        search_pool: list[EmailNode] = sent + received; 

        person_formatted: str = person_node_to_string(here);

        # --- FIX 1: ADDED THIS "FINDINGS" BLOCK ---
        conversation_history.append({
            "type": "found-emails-for-person",
            "content": f"At person {person_formatted}. Found sent emails: {str(sent_formatted)} and received emails: {str(received_formatted)}."
        });

        response = choose_next_email_node(person_formatted, str(sent_formatted), str(received_formatted), conversation_history);

        # --- FIX 2: REMOVED THE LOG THAT WAS HERE ---
        # (You had a log here with type "agent-retry-choice", which was incorrect)


        if response.option == "@end@" {
            
            # Update conversation history:
            # (This log is correct)
            conversation_history.append({
                "type": "agent-choice", 
                "content": f"I am ending the search. The answer is '{response.selection}' because: {response.explanation}"
            });

            report {"response": respond_to_user(conversation_history), "source": []};
        }
        elif response.option == "@query@" {
            
            # Update conversation history:
            conversation_history.append({
                "type": "agent-choice", 
                "content": f"I am starting a new query for '{response.selection}' because: {response.explanation}"
            });

            value = self.handle_email_query(response.selection);
            
            if type(value) == str {
                report {"response": value, "source": []};
            }
            else{
                visit value;
            }
        }
        elif response.option == "@selected@" {

            # (This log is correct)
            conversation_history.append({
                "type": "agent-choice", 
                "content": f"I am selecting email '{response.selection}' because: {response.explanation}"
            });
            
            # Select next email based on date
            selected_email_node: EmailNode = None;
            for email in search_pool {
                if(email.email_uuid == response.selection){
                    selected_email_node = email;
                    break;
                }
            }

            # If next email not found, try again 4 more times (5 total)
            counter: int = 0;
            while selected_email_node is None and counter < 4 {
                conversation_history.append({"type": "meta-error", "content": "email uuid did not verbatim match try again"});
                response = choose_next_email_node(person_formatted, str(sent_formatted), str(received_formatted), conversation_history);
                
                # --- FIX 3: CORRECTED THIS LOG BLOCK ---
                # Changed type from "select-email" to "agent-retry-choice"
                conversation_history.append({
                    "type": "agent-retry-choice", 
                    "content": f"I am acting on '{response.option}'. My new selection is '{response.selection}' because: {response.explanation}"
                });
            
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