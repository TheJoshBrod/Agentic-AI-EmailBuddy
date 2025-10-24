"""Contains all node types of the graph."""

node Person{
    has name: str;
    has email: str;
}

node Email{
    has date: str;
    has subject: str;
    has body: str;
    has email_uuid: str;
}
