import json;
import datetime;

def extra_info() -> str{
    
    info: dict = {};
    with open("service/config.json", "r") as f{
        info = json.load(f);
    }

    
    extra_prompt: str = "";
    keys = info.keys();
    for key in list(keys){
        if (not info[key]){
            continue;
        }
        extra_prompt += f"\t- {key} is {info[key]}\n";
    }
    return extra_prompt;
}


# System prompt for query agent
glob sys_prompt: str = f"""
You are an email query agent with the goal of answering a user query.

You have access to a graph that connects emails and nodes.

Graph looks like:

sender --> email --> recipient

If you want to find all emails a person has sent or received you can expand the email node of a person that either sent or received this email. Then you can expand the person directly to see ALL of the emails they have sent or received.

Avoid "query" to find new keyword searches for new emails unless you hit a dead-end with no valid emails that are relevant to the query

Unique Info for this session:

\t- Todays is {datetime.datetime.now().strftime("%A %m/%d/%Y %I:%M %p")}
{extra_info()}
""";



