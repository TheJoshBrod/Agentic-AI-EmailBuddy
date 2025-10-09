import json;

node Person{
    has name: str;
}

node Email{
    has date: str;
    has subject: str;
    has body: str;
}

walker FindRecipients{
    has targets: list[str] = [];
    has persons: list[Person] = [];
    has missing: list[str] = [];

    can start with `root entry {
        self.missing = self.targets;
        visit [-->];
    }

    can search with Person entry {
        if here.name in self.targets {
            # Track found people, remove from missing list
            self.persons.append(here);
            self.missing = [name for name in self.missing if name != here.name];
            disengage;
        }
        visit [-->];
    }
}

walker FindSender {
    has target: str;
    has person: Person = None;

    can start with `root entry {
        visit [-->];
    }

    can search with Person entry {
        if here.name == self.target {
            print(f"Found {here.name}!");
            self.found = True;
            self.sender = here;
            disengage;
        }
        visit [-->];
    }
}

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
            FindSend = FindSender(target=msg["from"]);
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
            FindRec = FindRecipients(targets=msg["to"]);
            root spawn FindRec;

            found = FindRec.persons;
            if len(found) != len(msg["to"]) {
                for person in FindRec.missing {
                    recipient = Person(name=msg["to"]);
                    root ++> recipient;
                    found.append(recipient);
                }
            }

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

    obj __specs__ {
        static has auth: bool = False;
    }

    can get_email_answer with `root entry {
        report {"response": self.query, "source": []};
    }
}