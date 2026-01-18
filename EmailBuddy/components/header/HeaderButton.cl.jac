cl import from antd { Button, message }

def:pub HeaderButton(props: dict) -> any {
    def uploadEmail() -> None {
        key = (Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2));
        message.loading({"content": "Uploading Emails...", "key": key});
        # TODO: Logic to upload email goes here
        setTimeout(lambda: message.success({"content": "Emails Successfully Uploaded!", "key": key}), 1000);
    }

    bgColor = "#4096ff";
    if "color" in props {
        bgColor = props.color;
    }

    iconElement = None;
    if "icon" in props {
        iconElement = <img src={props.icon} style={{"height": "20px"}}/>;
    }

    return <Button 
        type="primary"
        style={{
            "width": "140px",
            "height": "40px",
            "margin": "5px",
            "backgroundColor": bgColor 
        }}
        block
        onClick={lambda e: any -> None {
                if "onClick" in props {
                    props.onClick();
                } else {
                    uploadEmail();
                }
            }}
        >
        <div style={{"display": "flex", "alignItems": "center", "justifyContent": "center", "gap": "8px"}}>
            <p style={{"margin": 0}}>{props.text}</p>
            {iconElement}
        </div>
    </Button>;
}
