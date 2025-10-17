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


            # # Always create a new email node if uploaded
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
    has conversation_history: list = [];

    obj __specs__ {
        static has auth: bool = False;
    }

    can handle_query with `root entry{
        self.conversation_history.append({"sender": "user", "message": self.query});

        starting_emails: list[Email] = find_email_body(self.query);
        starting_people: list[People] = personSearch(self.query);
        
        print("\n\n\n\n\n\n\n\n\n");
        print(starting_emails);
        print("\n\n\n\n\n\n\n\n\n");
        report {"response": starting_emails[0], "source": []};
    }

    can handle_email_node with Email entry {
        # TODO:
        # Provide subject body/
    }

    
    can handle_person_node with Person entry {
        # TODO:
        # 
    }

}