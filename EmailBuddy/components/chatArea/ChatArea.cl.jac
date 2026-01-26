cl import from "@chatscope/chat-ui-kit-react" {
  MainContainer,
  ChatContainer,
  MessageList,
  Message,
  MessageInput,
  TypingIndicator
}
cl import "@chatscope/chat-ui-kit-styles/dist/default/styles.min.css";

def:pub ChatArea(props: dict) -> any {
    typing_indicator = None;
    if props.isTyping {
        typing_indicator = <TypingIndicator content="EmailBuddy is thinking" />;
    }

    isDark = props.theme == "dark";
    inputBorder = "1px solid #e0e0e0";
    inputBg = "#fff";
    bgColor = "#f0f2f5";

    if isDark {
        inputBorder = "1px solid #303030";
        inputBg = "#1f1f1f";
        bgColor = "#141414";
    }

    return (
        <div style={{
            "width": "100%",
            "height": "100%",
            "overflow": "hidden",
            "background": bgColor
        }}>
            <MainContainer style={{ "border": "none" }}>
                <ChatContainer>
                    <MessageList 
                        typingIndicator={typing_indicator}
                        style={{ "background": bgColor }}
                    >
                        {props.messages.map(lambda msg: any -> any {
                            return <Message
                                model={{
                                    "message": msg.message,
                                    "sender": msg.sender,
                                    "direction": msg.direction
                                }}
                                avatarSpacer={True}
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
                        style={{
                            "padding": "10px",
                            "borderTop": inputBorder,
                            "background": inputBg
                        }}
                    />
                </ChatContainer>
            </MainContainer>
        </div>
    );
}
