import {__jacJsx, __jacSpawn} from "@jac-client/utils";
import { useState } from "react";
import "./global.css";
import { MainContainer, ChatContainer, MessageList, Message, MessageInput } from "@chatscope/chat-ui-kit-react";
import "@chatscope/chat-ui-kit-styles/dist/default/styles.min.css";
import { Button, Input, Card, Typography, Space, message } from "antd";
function HeaderButton(props) {
  function uploadEmail() {
    let key = Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2);
    message.loading({"content": "Uploading Emails...", "key": key});
    setTimeout(() => message.success({"content": "Emails Successfully Uploaded!", "key": key}), 1000);
  }
  let bgColor = "#4096ff";
  if (props.color) {
    bgColor = props.color;
  }
  return __jacJsx(Button, {"type": "primary", "style": {"width": "140px", "height": "40px", "margin": "5px"}, "block": true, "onClick": e => {
    if (props.onClick) {
      props.onClick();
    } else {
      uploadEmail();
    }
  }}, [__jacJsx("p", {}, [props.text]), __jacJsx("img", {"src": props.icon, "style": {"height": "30px"}}, [])]);
}
function MyApp() {
  let [messages, setMessages] = useState([{"message": "Hello! How can I help you today?", "sender": "Assistant", "direction": "incoming"}]);
  let [isTyping, setIsTyping] = useState(false);
  function handleSend(message) {
    let newMessage = {"message": message, "sender": "User", "direction": "outgoing"};
    let newMessages = messages.concat([newMessage]);
    setMessages(newMessages);
    setIsTyping(true);
    setTimeout(e => {
      let botResponse = {"message": `You said: ${message}`, "sender": "Assistant", "direction": "incoming"};
      setMessages(newMessages.concat([botResponse]));
      setIsTyping(false);
    }, 1000);
  }
  function clearChat() {
    message.success("Cleared Chat!");
    setMessages([{"message": "How can I help you?", "sender": "Assistant", "direction": "incoming"}]);
  }
  return __jacJsx("div", {"style": {"height": "100vh", "display": "flex", "flexDirection": "column", "backgroundColor": "#917093"}}, [__jacJsx(Card, {"style": {margin: "10px 100px 10px", borderRadius: "8px", backgroundColor: "#dcaadf", border: "4px solid white", boxShadow: "0px 4px 8px rgba(0,0,0,0.3)", position: "relative"}}, [__jacJsx("div", {"style": {position: "absolute", left: "50%", top: "50%", transform: "translateX(-50%) translateY(-50%)", textAlign: "center"}}, [__jacJsx(Typography.Title, {"level": 3, "style": {margin: 0}}, ["EmailBuddy"]), __jacJsx(Typography.Text, {"type": "secondary"}, ["Total Emails Uploaded: ", messages.length])]), __jacJsx("div", {"style": {display: "flex", justifyContent: "flex-end", gap: "8px"}}, [__jacJsx(HeaderButton, {"text": "Upload Email", "icon": "/static/assets/upload-file.svg"}, []), __jacJsx(HeaderButton, {"text": "Clear Chat", "onClick": clearChat, "color": "#ff4d4f", "icon": "/static/assets/trash.svg"}, [])])]), __jacJsx("div", {"style": {"flex": 1, "position": "relative", "margin": "0px 100px 50px", "borderRadius": "8px", "backgroundColor": "#dcaadf", "border": "4px solid white", "box-shadow": "0px 4px 8px rgba(0,0,0,0.3)"}}, [__jacJsx(MainContainer, {"style": {"backgroundColor": "#dcaadf", "height": "1000px", "overflow": "auto"}}, [__jacJsx(ChatContainer, {}, [__jacJsx(MessageList, {"style": {"backgroundColor": "#dcaadf"}}, [messages.map(msg => {
    return __jacJsx(Message, {"model": {"message": msg.message, "sender": msg.sender, "direction": msg.direction}}, []);
  })]), __jacJsx(MessageInput, {"placeholder": "Type your message here...", "onSend": message => {
    handleSend(message);
  }, "attachButton": false}, [])])])])]);
}
function app() {
  return MyApp();
}
export { HeaderButton, MyApp, app };
