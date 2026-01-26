cl import from antd { Layout, Typography, Space, Button, Switch }
cl import from "@ant-design/icons" { UploadOutlined, DeleteOutlined, SunOutlined, MoonOutlined }

def:pub Header(props: dict) -> any {
    isDark = props.theme == "dark";
    
    headerBg = "#fff";
    headerShadow = "0 2px 8px #f0f1f2";
    headerBorder = "none";
    titleColor = "#1f1f1f";
    subColor = None;
    uploadBtnType = "default";
    
    if isDark {
        headerBg = "#1f1f1f";
        headerShadow = "0 2px 8px rgba(0,0,0,0.4)";
        headerBorder = "1px solid #303030";
        titleColor = "#fff";
        subColor = "rgba(255,255,255,0.45)";
        uploadBtnType = "primary";
    }

    return (
        <div style={{
            "display": "flex",
            "justifyContent": "space-between",
            "alignItems": "center",
            "padding": "16px 24px",
            "background": headerBg,
            "boxShadow": headerShadow,
            "zIndex": 10,
            "borderBottom": headerBorder
        }}>
            <div>
                <Typography.Title level={4} style={{ "margin": 0, "color": titleColor }}>
                    EmailBuddy
                </Typography.Title>
                <Typography.Text type="secondary" style={{ "fontSize": "12px", "color": subColor }}>
                    {props.messageCount + " emails indexed"}
                </Typography.Text>
            </div>

            <Space>
                <Switch
                    checkedChildren={<MoonOutlined />}
                    unCheckedChildren={<SunOutlined />}
                    checked={isDark}
                    onChange={props.toggleTheme}
                />
                
                <Button 
                    icon={<UploadOutlined />} 
                    onClick={props.onUpload}
                    type={uploadBtnType}
                    ghost={isDark}
                >
                    Upload Emails
                </Button>
                <Button 
                    type="text" 
                    danger={True}
                    icon={<DeleteOutlined />} 
                    onClick={props.onClearChat}
                >
                    Clear Chat
                </Button>
            </Space>
        </div>
    );
}