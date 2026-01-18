"""Main entry point for the Jac client application."""

# Server-side imports
include service.server;

# Initialize root node on server startup
walker init_root {
    can setup with `root entry {
        print("Root node initialized successfully");
    }
}

# This runs when the server starts
with entry {
    root spawn init_root();
}

# Client-side imports
cl import from react { useEffect }
cl import from .components.EmailBuddyLayout { EmailBuddyLayout }

# Client-side component
cl {
    def:pub app() -> None {
        
        async def handle_query(query: str) -> any {
            return await root spawn ask_email(query=query);
        }

        async def handle_upload(emails: list) -> any {
            return await root spawn upload_emails(raw_emails=emails);
        }

        return (
            <div>
                <EmailBuddyLayout 
                    onQuery={handle_query}
                    onUploadEmails={handle_upload}
                />
            </div>
        );
    }
}