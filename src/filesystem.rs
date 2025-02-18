use indextree::{Arena, NodeId};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Item {
    pub name: String,
    pub text: String,
    pub mutable: bool,
    pub executable: bool,
}
impl Item {
    pub fn new(name: &str, text: &str, mutable: bool, executable: bool) -> Self {
        Self {
            name: name.to_string(),
            text: text.to_string(),
            mutable,
            executable,
        }
    }
}

pub fn get_item(file_system: &Arena<Item>, path: Vec<String>, root: &NodeId) -> Option<NodeId> {
    let mut current_item = *root;
    for name in path {
        if let Some(found_item) = current_item.children(file_system).find(|&child| file_system[child].get().name == *name) {
            current_item = found_item;
        } else {
            return None;
        }
    }

    Some(current_item)
}
