import json;

walker upload_emails{
    has raw_emails: list;

    obj __specs__ {
        static has auth: bool = False;
    }

    can upload_email with `root entry{
        emails: list = self.raw_emails;
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