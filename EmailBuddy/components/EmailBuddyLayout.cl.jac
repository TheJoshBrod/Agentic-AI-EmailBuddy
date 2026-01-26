
cl import from react { useState, useRef, useEffect }
cl import from antd { message, Layout }
cl import from .header.Header { Header }
cl import from .chatArea.ChatArea { ChatArea }

def:pub EmailBuddyLayout(props: dict) -> any {
    # Theme state with safe initialization
    [theme, setTheme] = useState("light");

    useEffect(lambda -> None {
        if window.matchMedia("(prefers-color-scheme: dark)").matches {
            setTheme("dark");
        }
    }, []);

    def toggleTheme() -> None {
        newTheme = "dark";
        if theme == "dark" {
            newTheme = "light";
        }
        setTheme(newTheme);
    }

    # State for messages
    [messages, setMessages] = useState([
        {
            "message": "Hello! How can I help you today?",
            "sender": "Assistant",
            "direction": "incoming"
        }
    ]);
    
    # State for typing indicator
    [isTyping, setIsTyping] = useState(False);

    # State for email count
    [emailCount, setEmailCount] = useState(0);

    # Ref for file input
    fileInputRef = useRef(None);

    # Function to handle sending a message
    def handleSend(text: str) -> None {
        # Add user message to the list
        newMessage = {
            "message": text,
            "sender": "User",
            "direction": "outgoing"
        };
        
        newMessages = messages.concat([newMessage]);
        setMessages(newMessages);
        setIsTyping(True);

        async def query_backend() -> None {
            # Spawn the ask_email walker
            response = await props.onQuery(text);

            # The walker reports a list of dictionaries, we access the first report
            botResponse = {};
            if response.reports {
                 result = response.reports[0];
                 botResponse = {
                    "message": result["response"],
                    "sender": "Assistant",
                    "direction": "incoming"
                 };
            } else {
                 botResponse = {
                    "message": "Sorry, I couldn't process that request.",
                    "sender": "Assistant",
                    "direction": "incoming"
                 };
            }

            setMessages(newMessages.concat([botResponse]));
            setIsTyping(False);
        }
        query_backend();
    }
    
    # Fetch email count
    async def fetchEmailCount() -> None {
        if "onGetCount" in props {
            response = await props.onGetCount();
            if response.reports {
                 result = response.reports[0];
                 setEmailCount(result["count"]);
            }
        }
    }

    useEffect(lambda -> None {
        fetchEmailCount();
    }, []);

    # Trigger file input click
    def handleUpload() -> None {
        if fileInputRef.current {
            fileInputRef.current.click();
        }
    }

    # Handle file selection and upload
    def handleFileChange(event: any) -> None {
        file = event.target.files[0];
        if not file {
            return;
        }

        reader = Reflect.construct(FileReader, []);
        
        reader.onload = lambda e: any -> None {
            try {
                content = e.target.result;
                emails = JSON.parse(content);
                
                if not Array.isArray(emails) {
                    message.error("Invalid format: Expected a JSON array of emails");
                    return;
                }

                message.loading("Uploading emails...");

                async def upload() -> None {
                    try {
                        # Spawn upload_emails walker with parsed data
                        await props.onUploadEmails(emails);
                        message.success(f"Successfully uploaded {emails.length} emails!");
                        await fetchEmailCount();
                    } except any as error {
                         console.error(error);
                         message.error("Failed to upload emails to backend");
                    }
                }
                upload();

            } except any as error {
                console.error(error);
                message.error("Failed to parse JSON file");
            }
        };

        reader.readAsText(file);
        
        # Reset input value to allow uploading the same file again if needed
        event.target.value = "";
    }

    # Function to clear chat
    def clearChat() -> None {
        message.success("Cleared Chat!");
        setMessages([
            {
                "message": "How can I help you?",
                "sender": "Assistant",
                "direction": "incoming"
            }
        ]);
    }

    mainBg = "#f0f2f5";
    if theme == "dark" {
        mainBg = "#141414";
    }

    return (
        <Layout style={{ "height": "100vh", "background": mainBg }}>
            <Header 
                messageCount={emailCount} 
                onClearChat={clearChat} 
                onUpload={handleUpload}
                theme={theme}
                toggleTheme={toggleTheme}
            />
            <Layout.Content style={{ "padding": "0 0" }}>
                <ChatArea 
                    messages={messages} 
                    onSend={handleSend}
                    isTyping={isTyping} 
                    theme={theme}
                />
            </Layout.Content>
            <input 
                type="file" 
                ref={fileInputRef}
                style={{"display": "none"}}
                accept=".json"
                onChange={handleFileChange}
            />
        </Layout>
    );
}
