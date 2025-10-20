"""Contains all node types of the graph."""

node Person{
    has name: str;
}
    
def person_node_to_string(person: Person) -> str{
    return person.name;
}

node Email{
    has date: str;
    has subject: str;
    has body: str;
}

def email_node_to_string(email: Email) -> str{
    output: str = "";
    output += "Subject:\n" + email.subject;
    output += "\nDate\n:" + email.date;
    output += "\n\nBody:\n" + email.body;
    return output;
}
