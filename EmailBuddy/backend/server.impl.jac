
can ask_email.handle_email_query(query: str) -> None{
    
    # Initialized vars
    initial_emails: list[Email] = [];
    option: str = "@query@";

    # Loops until finds satisfiable email to explore
    while option == "@query@" {
        # Get starting nodes of emails to explore
        starting_emails: tuple[str] = find_emails(query);
        uuids: list[str] = [email[0] for email in starting_emails];
        FindEmails = FindEmailNode(targets=uuids);
        here spawn FindEmails;

        # Choose which email to travel to
        initial_emails = FindEmails.emails;
        initial_emails_formatted: list[str] = [email_node_to_string(email) for email in initial_emails];
        response = choose_initial_email_node(str(initial_emails_formatted), self.conversation_history);

        # Update findings to conversation history
        self.conversation_history.append({"type": "found-emails", "content": initial_emails_formatted});
        self.conversation_history.append({"type": "tool-call-response", "content": str(response.selection)});
        self.conversation_history.append({"role": "user", "content": response.explanation});

        # Extract relevant information
        query = response.selection;
        option = response.option;
    }
    if (response.option == "@end@"){
        # If got answer from initial search, respond with answer
        # TODO: Separate answer function?
        report {"response": respond_to_user(self.conversation_history), "source": []};            
    }
    else if response.option == "@selected@" {

        # Select next email based on uuid
        selected_email_node: Email = None;
        for email in initial_emails {
            if(email.email_uuid == response.selection){
                selected_email_node = email;
                break;
            }
        }

        # If next email not found, try again 4 more times (5 total)
        counter: int = 0;
        while selected_email_node is None and counter < 4 {
            self.conversation_history.append({"type": "meta-error", "content": "email uuid did not verbatim match try again"})
            response = retry_extract_identifier(self.conversation_history);
            self.conversation_history.append({"type": "selected", "content": str(response.selection)});
            self.conversation_history.append({"role": "system", "content": response.explanation});
            for email in initial_emails {
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