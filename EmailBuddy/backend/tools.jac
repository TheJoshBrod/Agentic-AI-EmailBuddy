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
        if here.name in self.targets {
            # Track found people, remove from missing list
            self.persons.append(here);
            self.missing = [name for name in self.missing if name != here.name];
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