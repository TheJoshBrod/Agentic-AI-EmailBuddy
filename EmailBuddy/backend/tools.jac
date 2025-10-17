"""Contains all the helper walkers and tool calls."""

include nodes;

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
        if len(missing) == 0 {
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


def emailSearch(query: str) -> list[Email]{
    # TODO:
    # Create query embedding
    # Vector Search
    # Find email nodes
}

def personSearch(query: str) -> list[Person]{
    # TODO:
    # Create query embedding
    # Vector Search
    # Find email nodes
}

def registerEmail(msg: Email) -> None{
    # TODO:
    # Create subject and body embeddings
    # Put into DB(?)
}

def registerPerson(person: Person) -> None{
    # TODO:
    # Create subject and body embeddings
    # Put into DB(?)
}

def normalize(email: str) -> str{
    if "<" in email{
        return email.split("<")[1].split(">")[0].strip();
    }
    return email.strip();
}