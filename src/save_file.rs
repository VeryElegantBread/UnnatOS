use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::fs::File;
use std::io::{Read, Write};
use indextree::{Arena, NodeId};

use crate::{get_item, Item};

#[derive(Debug, Serialize, Deserialize)]
struct SerializableItem {
    id: String,
    parent: Option<String>,
    item: Item,
}

pub fn save_file_system(file_system: &Arena<Item>, root: NodeId, path: &str) -> std::io::Result<()> {
    let mut cleaned_file_system = file_system.clone();
    if let Some(shell) = get_item(&cleaned_file_system, vec!["System".to_string(), "Shell.lua".to_string()], &root) {
        shell.remove(&mut cleaned_file_system);
    }
    for child in get_item(&cleaned_file_system, vec!["System".to_string(), "Backups".to_string()], &root).expect("Failed to find Backups item").children(&cleaned_file_system).collect::<Vec<NodeId>>() {
        child.remove(&mut cleaned_file_system);
    }

    let mut serializable_nodes = Vec::new();

    for node_id in root.descendants(&cleaned_file_system) {
        let node = &cleaned_file_system[node_id];
        let parent = node_id.ancestors(&cleaned_file_system).nth(1).map(|p| p.to_string());
        serializable_nodes.push(SerializableItem {
            id: node_id.to_string(),
            parent,
            item: node.get().clone(),
        });
    }

    let json = serde_json::to_string_pretty(&serializable_nodes)?;
    let mut file = File::create(path)?;
    file.write_all(json.as_bytes())?;

    Ok(())
}

pub fn load_file_system(path: &str) -> std::io::Result<(Arena<Item>, NodeId)> {
    let mut file = File::open(path)?;
    let mut json = String::new();
    file.read_to_string(&mut json)?;

    let serializable_items: Vec<SerializableItem> = serde_json::from_str(&json)?;
    let mut file_system = Arena::new();
    let mut node_map = HashMap::new();
    let mut child_set = HashSet::new();

    for item in &serializable_items {
        let item_id = file_system.new_node(item.item.clone());
        node_map.insert(item.id.clone(), item_id);
    }

    for node in &serializable_items {
        if let Some(parent_id) = &node.parent {
            if let (Some(&parent_node), Some(&child_node)) = (node_map.get(parent_id), node_map.get(&node.id)) {
                parent_node.append(child_node, &mut file_system);
                child_set.insert(child_node);
            }
        }
    }

    let root = node_map
        .values()
        .find(|&&node_id| !child_set.contains(&node_id))
        .expect("Failed to find root item");

    let system = get_item(&file_system, vec!["System".to_string()], root).expect("Failed to find System item");
    let backups = get_item(&file_system, vec!["Backups".to_string()], &system).expect("Failed to find Backups item");
    let _ = get_item(&file_system, vec!["Programs".to_string()], &system).expect("Failed to find Programs item");

    let shell = file_system.new_node(Item::new("Shell.lua", include_str!("lua_scripts/Shell.lua"), false, true));
    system.append(shell, &mut file_system);
    let read = file_system.new_node(Item::new("read", include_str!("lua_scripts/read.lua"), false, true));
    backups.append(read, &mut file_system);
    let items = file_system.new_node(Item::new("items", include_str!("lua_scripts/items.lua"), false, true));
    backups.append(items, &mut file_system);
    let exit = file_system.new_node(Item::new("exit", include_str!("lua_scripts/exit.lua"), false, true));
    backups.append(exit, &mut file_system);
    let new = file_system.new_node(Item::new("new", include_str!("lua_scripts/new.lua"), false, true));
    backups.append(new, &mut file_system);
    let remove = file_system.new_node(Item::new("remove", include_str!("lua_scripts/remove.lua"), false, true));
    backups.append(remove, &mut file_system);
    let save = file_system.new_node(Item::new("save", include_str!("lua_scripts/save.lua"), false, true));
    backups.append(save, &mut file_system);
    let se = file_system.new_node(Item::new("se", include_str!("lua_scripts/se.lua"), false, true));
    backups.append(se, &mut file_system);
    let write = file_system.new_node(Item::new("write", include_str!("lua_scripts/write.lua"), false, true));
    backups.append(write, &mut file_system);


    Ok((file_system, *root))
}

pub fn new(path: &str) {
    let mut file_system = Arena::new();
    
    let root = file_system.new_node(Item::new("~", "This is the root item!", false, false));

    let system = file_system.new_node(Item::new("System", "UnnatOS\nBy @VeryElegantBread", false, false));
    root.append(system, &mut file_system);
    let programs = file_system.new_node(Item::new("Programs", "Programs you can run without the whole path", false, false));
    system.append(programs, &mut file_system);
    let backups = file_system.new_node(Item::new("Backups", "Backups of the default programs", false, false));
    system.append(backups, &mut file_system);
    let startup = file_system.new_node(Item::new("Startup.lua", "-- code in this file will be ran when the OS boots", true, true));
    system.append(startup, &mut file_system);
    let read = file_system.new_node(Item::new("read", include_str!("lua_scripts/read.lua"), true, true));
    programs.append(read, &mut file_system);
    let items = file_system.new_node(Item::new("items", include_str!("lua_scripts/items.lua"), true, true));
    programs.append(items, &mut file_system);
    let exit = file_system.new_node(Item::new("exit", include_str!("lua_scripts/exit.lua"), true, true));
    programs.append(exit, &mut file_system);
    let new = file_system.new_node(Item::new("new", include_str!("lua_scripts/new.lua"), true, true));
    programs.append(new, &mut file_system);
    let remove = file_system.new_node(Item::new("remove", include_str!("lua_scripts/remove.lua"), true, true));
    programs.append(remove, &mut file_system);
    let save = file_system.new_node(Item::new("save", include_str!("lua_scripts/save.lua"), true, true));
    programs.append(save, &mut file_system);
     let se = file_system.new_node(Item::new("se", include_str!("lua_scripts/se.lua"), true, true));
    programs.append(se, &mut file_system);
    let write = file_system.new_node(Item::new("write", include_str!("lua_scripts/write.lua"), true, true));
    programs.append(write, &mut file_system);
    
    let _ = save_file_system(&file_system, root, path);
}
