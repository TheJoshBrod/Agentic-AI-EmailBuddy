cl import from antd { Card, Typography }
cl import from .HeaderButton { HeaderButton }

def:pub Header(props: dict) -> any {
    return (
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
                    Total Emails Uploaded: {props.messageCount}
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
                    onClick={props.onUpload}
                    icon="/static/assets/upload-file.svg"
                />
                <HeaderButton
                    text="Clear Chat"
                    onClick={props.onClearChat}
                    color="#ff4d4f"
                    icon="/static/assets/trash.svg"
                />
            </div>
        </Card>
    );
}