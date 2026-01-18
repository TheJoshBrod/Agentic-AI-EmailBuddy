# public graph access
glob public_api_key: str = "123456"; # change this to your own api key

walker validate_api_key {
    has api_key: str = "";
    obj __specs__ {
        static has auth: bool = False;  # Skip auto endpoint generation from walker
    }
    can validate_api_key with `root entry {     
        if(self.api_key == public_api_key) {
            report True;
        } else {
            report False;
        }
    }
}

walker get_public_nodes {
    has node_id: str = "";
    has api_key: str = "";
    obj __specs__ {
        static has auth: bool = False;  
    }
    can get_public_nodes with `root entry {
        if(self.api_key != public_api_key) {
            raise "Invalid API key";
            disengage;
        }
        if(self.node_id == "") {
            report jid(here);
        } else {
            selected_node = &self.node_id;
            attached_nodes = [selected_node-->];
            report attached_nodes;
        }  
    }
}