cl import from "@chatscope/chat-ui-kit-react" {
  MainContainer,
  ChatContainer,
  MessageList,
  Message,
  MessageInput
}
cl import "@chatscope/chat-ui-kit-styles/dist/default/styles.min.css";

def:pub ChatArea(props: dict) -> any {
    return (
        <div style={{
            "flex": 1,
            "position": "relative",
            "margin": "0px 100px 50px",
            "borderRadius": "8px",
            "backgroundColor": "#dcaadf",
            "border": "4px solid white",
            "boxShadow": "0px 4px 8px rgba(0,0,0,0.3)",
            "overflow": "hidden"
        }}>
            <MainContainer style={{
                "backgroundColor": "#dcaadf", 
                "height": "100%" 
            }}>
                <ChatContainer>
                    <MessageList style={{"backgroundColor": "#dcaadf"}}>
                        {props.messages.map(lambda msg: any -> any {
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
                            if "onSend" in props {
                                props.onSend(message);
                            }
                        }}
                        attachButton={False}
                    />
                </ChatContainer>
            </MainContainer>
        </div>
    );
}
