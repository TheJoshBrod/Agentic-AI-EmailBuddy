"""Contains all the API Endpoints."""

# Python Libraries
import json;

# Jac Files
include tools;
include nodes;

walker upload_emails{
    has raw_emails: list;

    obj __specs__ {
        static has auth: bool = False;
    }

    can upload_email with `root entry{
        emails: list = self.raw_emails;
        for msg in emails {

            # Spawn walker to check if sender node already exists
            # If it exists set to existing node
            # else create new node connected to root
            FindSend = FindSenderNode(target=msg["from"]);
            root spawn FindSend;

            sender = None;
            if FindSend.person is None {
                sender = Person(name=msg["from"]);
                root ++> sender;
            }
            else{
                sender = FindSend.person;
            }

            # Spawn walker to check if recipient node already exists
            # If it exists set to existing node
            # else create new node connected to root
            FindRec = FindRecipientNodes(targets=msg["to"]);
            root spawn FindRec;

            found = FindRec.persons;
            if len(found) != len(msg["to"]) {
                for person in FindRec.missing {
                    recipient = Person(name=msg["to"]);
                    root ++> recipient;
                    found.append(recipient);
                }
            }

            # Always create a new email node if uploaded
            email = Email(date=msg["date"], subject=msg["subject"], body=msg["body"]);
            root ++> email;
            sender ++> email;
            for person in found{
                email ++> person;
            }
        }
    }
}

walker ask_email {
    has query: str;
    has conversation_history: list = [];

    obj __specs__ {
        static has auth: bool = False;
    }

    can handle_query with `root entry {
        self.conversation_history.append({"sender": "user", "message": self.query});
        
        starting_emails: list[Emails] = emailSearch(self.query);
        starting_people: list[People] = personSearch(self.query);

        report {"response": self.query, "source": []};
    }

    can handle_email_node with `Email entry {
        # TODO:
        # Provide subject body/
    }

    
    can handle_person_node with `Person entry {
        # TODO:
        # 
    }

}