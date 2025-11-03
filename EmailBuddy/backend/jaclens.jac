walker get_attached_nodes {
    has node_id: str = "";
    can get_attach_nodes with `root entry {
        if(self.node_id == "") {
            report jid(here);
        } else {
            selected_node = &self.node_id;
            attached_nodes = [selected_node-->];
            report attached_nodes;
        }
    }
}

walker update_node_data {
    has node_id: str = "";
    has node_data: dict = {};
    can update_node_data with `root entry {
        selected_node = &self.node_id;
        selected_node.__dict__.update(self.node_data);
        report selected_node;
    }
}