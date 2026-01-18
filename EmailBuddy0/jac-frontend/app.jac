# Pages
cl import from react {useState}
cl import ".global.css";
"""Importing Chat UI components."""
cl import from "@chatscope/chat-ui-kit-react" {
  MainContainer,
  ChatContainer,
  MessageList,
  Message,
  MessageInput
}
cl import "@chatscope/chat-ui-kit-styles/dist/default/styles.min.css";
cl import from antd { Button, Input, Card, Typography, Space, message }

cl {
    def HeaderButton(props: any) -> any {
        def uploadEmail() -> None {
            let key = (Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2));
            message.loading({"content": "Uploading Emails...", "key": key});
            # TODO: Logic to upload email goes here
            setTimeout(lambda: message.success({"content": "Emails Successfully Uploaded!", "key": key}), 1000);
        }

        let bgColor = "#4096ff";
        if props.color {
            bgColor = props.color;
        }

        return <Button 
            type="primary"
            style={{
                "width": "140px",
                "height": "40px",
                "margin": "5px"
            }}
            block
            onClick={lambda e: any -> None {
                    if props.onClick {
                        props.onClick();
                    } else {
                        uploadEmail();
                    }
                }}
            >
            <p>{props.text}</p>
            <img src={props.icon} style={{"height": "30px"}}/>
        </Button>;
    }


    def MyApp() -> any {
        # State for messages
        [messages, setMessages] = useState([
            {
                "message": "Hello! How can I help you today?",
                "sender": "Assistant",
                "direction": "incoming"
            }
        ]);
        
        # State for typing indicator
        [isTyping, setIsTyping] = useState(false);

        # Function to handle sending a message
        def handleSend(message: str) -> None {
            # Add user message to the list
            newMessage = {
                "message": message,
                "sender": "User",
                "direction": "outgoing"
            };
            
            newMessages = messages.concat([newMessage]);
            setMessages(newMessages);
            
            # TODO: Handle EmailBuddy Response
            setIsTyping(true);
            
            setTimeout(lambda e: any -> None {
                botResponse = {
                    "message": f"You said: {message}",
                    "sender": "Assistant",
                    "direction": "incoming"
                };
                setMessages(newMessages.concat([botResponse]));
                setIsTyping(false);
            }, 1000);
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

        return <div style={{
            "height": "100vh",
            "display": "flex",
            "flexDirection": "column",
            "backgroundColor": "#917093"
        }}>
            # Header
            <Card
                style={{
                    margin: "10px 100px 10px",
                    borderRadius: "8px",
                    backgroundColor: "#dcaadf",
                    border: "4px solid white",
                    boxShadow: "0px 4px 8px rgba(0,0,0,0.3)",
                    position: "relative"
                }}
            >
                <div
                    style={{
                    position: "absolute",
                    left: "50%",
                    top: "50%",
                    transform: "translateX(-50%) translateY(-50%)",
                    textAlign: "center",
                    }}
                >
                    <Typography.Title level={3} style={{ margin: 0 }}>
                    EmailBuddy
                    </Typography.Title>
                    <Typography.Text type="secondary">
                    Total Emails Uploaded: {messages.length}
                    </Typography.Text>
                </div>

               
                <div
                    style={{
                    display: "flex",
                    justifyContent: "flex-end",
                    gap: "8px",
                    }}
                >
                    <HeaderButton
                    text="Upload Email"
                    icon="/static/assets/upload-file.svg"
                    />
                    <HeaderButton
                    text="Clear Chat"
                    onClick={clearChat}
                    color="#ff4d4f"
                    icon="/static/assets/trash.svg"
                    />
                </div>
            </Card>


            # Chat Container
            <div style={{
                "flex": 1,
                "position": "relative",
                "margin": "0px 100px 50px",
                "borderRadius": "8px",
                "backgroundColor": "#dcaadf",
                "border": "4px solid white",
                "box-shadow": "0px 4px 8px rgba(0,0,0,0.3)"
            }}>
                <MainContainer style={{
                "backgroundColor": "#dcaadf", "height":"1000px", "overflow": "auto"}}>
                    <ChatContainer>
                        <MessageList style={{"backgroundColor": "#dcaadf"}}>
                            {messages.map(lambda msg: any -> any {
                                return <Message
                                    model={{
                                        "message": msg.message,
                                        "sender": msg.sender,
                                        "direction": msg.direction
                                    }}
                                />;
                            })}
                        </MessageList>
                        <MessageInput 
                            placeholder="Type your message here..." 
                            onSend={lambda message: str -> None {
                                handleSend(message);
                            }}
                            attachButton={false}
                        />
                    </ChatContainer>
                </MainContainer>
            </div>
        </div>;
    }

    def app() -> any {
        return MyApp();
    }
}