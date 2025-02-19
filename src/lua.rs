use indextree::{Arena, NodeId};
use mlua::{prelude::{LuaTable, LuaError}, Error, Lua};
use termion::{input::TermRead, raw::IntoRawMode};
use std::{io::{self, Write}, sync::{Arc, Mutex}};
use reqwest::blocking;

use crate::{get_item, save_file_system, Item};

pub fn run(file_system: &mut Arc<Mutex<Arena<Item>>>, root: NodeId, file_path: &str, safe_mode: bool) -> Result<(), Error> {
    let lua = Lua::new();
    let package: LuaTable = lua.globals().get("package")?;

    let file_system_clone = Arc::clone(file_system);
    let root_clone = root;
    let searchers: LuaTable = package.get("searchers")?;
    searchers.set(1, lua.create_function(move |lua, module: String| {
        let mut path = vec![];
        for i in module.split('/') {
            path.push(i.to_string());
        }
        let file_system_bind = file_system_clone.lock().unwrap();
        if let Some(item) = get_item(&file_system_bind, path, &root_clone) {
            lua.load(&file_system_bind[item].get().text).into_function()
        } else {
            let err_func = lua.create_function(move |_, ()| {
                Ok(format!("module '{}' not found", module))
            })?;
            Ok(err_func)
        }
    })?)?;

    let file_system_clone = Arc::clone(file_system);
    let root_clone = root;
    let lua_get_text = lua.create_function(move |_, path: Vec<String>| {
        let file_system_bind = file_system_clone.lock().unwrap();
        if let Some(item) = get_item(&file_system_bind, path, &root_clone) {
            return Ok(Some(file_system_bind[item].get().text.clone()));
        } else {
            return Ok(None);
        };
    })?;
    lua.globals().set("get_text", lua_get_text)?;

    let file_system_clone = Arc::clone(file_system);
    let root_clone = root;
    let lua_is_mutable = lua.create_function(move |_, path: Vec<String>| {
        let file_system_bind = file_system_clone.lock().unwrap();
        if let Some(item) = get_item(&file_system_bind, path, &root_clone) {
            return Ok(Some(file_system_bind[item].get().mutable));
        } else {
            return Ok(None);
        };
    })?;
    lua.globals().set("is_mutable", lua_is_mutable)?;

    let file_system_clone = Arc::clone(file_system);
    let root_clone = root;
    let lua_is_executable = lua.create_function(move |_, path: Vec<String>| {
        let file_system_bind = file_system_clone.lock().unwrap();
        if let Some(item) = get_item(&file_system_bind, path, &root_clone) {
            return Ok(Some(file_system_bind[item].get().executable));
        } else {
            return Ok(None);
        };
    })?;
    lua.globals().set("is_executable", lua_is_executable)?;

    let file_system_clone = Arc::clone(file_system);
    let root_clone = root;
    let lua_item_exists = lua.create_function(move |_, path: Vec<String>| {
        match get_item(&file_system_clone.lock().unwrap(), path, &root_clone) {
            Some(_) => Ok(true),
            _ => Ok(false),
        }
    })?;
    lua.globals().set("item_exists", lua_item_exists)?;

    let file_system_clone = Arc::clone(file_system);
    let root_clone = root;
    let lua_get_children = lua.create_function(move |_, path: Vec<String>| {
        let file_system_bind = file_system_clone.lock().unwrap();
        if let Some(parent_item) = get_item(&file_system_bind, path, &root_clone) {
            let mut item_names = vec![];
            for item in parent_item.children(&file_system_bind) {
                item_names.push(file_system_bind[item].get().name.clone());
            }
            return Ok(Some(item_names));
        } else {
            return Ok(None);
        }
    })?;
    lua.globals().set("get_children", lua_get_children)?;

    let file_system_clone = Arc::clone(file_system);
    let root_clone = root;
    let lua_new_item = lua.create_function(move |_, (path, executable): (Vec<String>, bool)| {
        let mut file_system_bind = file_system_clone.lock().unwrap();
        if path.is_empty() {
            return Err(LuaError::external("The provided path is empty"));
        } else if let Some(parent_item) = get_item(&file_system_bind, path[..path.len() - 1].to_vec(), &root_clone) {
            let name = &path[path.len() - 1];
            if ["", ".", ".."].contains(&&name[..]) {
                return Err(LuaError::external(format!("disalowed name: {:?}", name)));
            }
            for char in name.chars() {
                match char {
                    '/' => return Err(LuaError::external(format!("disalowed name: {:?}", name))),
                    '~' => return Err(LuaError::external(format!("disalowed name: {:?}", name))),
                    _ => {},
                }
            }

            if parent_item.children(&file_system_bind).any(|item| file_system_bind[item].get().name == *name) {
                return Ok(true);
            }

            let item = file_system_bind.new_node(Item::new(name, "", true, executable));
            parent_item.append(item, &mut file_system_bind);

            return Ok(false);
        } else {
            return Err(LuaError::external("Could't find the parent item"));
        };
    })?;
    lua.globals().set("new_item", lua_new_item)?;

    let file_system_clone = Arc::clone(file_system);
    let root_clone = root;
    let lua_remove_item = lua.create_function(move |_, path: Vec<String>| {
        let mut file_system_bind = file_system_clone.lock().unwrap();
        if let Some(item) = get_item(&file_system_bind, path, &root_clone) {
            if !file_system_bind[item].get().mutable {
                return Ok(false);
            };
            item.remove_subtree(&mut file_system_bind);
            return Ok(true);
        } else {
            return Err(LuaError::external("Could't find the item"));
        };
    })?;
    lua.globals().set("remove_item", lua_remove_item)?;

    let file_system_clone = Arc::clone(file_system);
    let root_clone = root;
    let lua_set_executable = lua.create_function(move |_, (path, value): (Vec<String>, bool)| {
        let mut file_system_bind = file_system_clone.lock().unwrap();
        if let Some(item_id) = get_item(&file_system_bind, path, &root_clone) {
            if !file_system_bind[item_id].get().mutable {
                return Ok(false);
            };
            let item = file_system_bind.get_mut(item_id).unwrap();
            item.get_mut().executable = value;
            return Ok(true);
        } else {
            return Err(LuaError::external("Could't find the item"));
        }
    })?;
    lua.globals().set("set_executable", lua_set_executable)?;

    let file_system_clone = Arc::clone(file_system);
    let root_clone = root;
    let lua_set_text = lua.create_function(move |_, (path, text): (Vec<String>, String)| {
        let mut file_system_bind = file_system_clone.lock().unwrap();
        if let Some(item_id) = get_item(&file_system_bind, path, &root_clone) {
            if !file_system_bind[item_id].get().mutable {
                return Ok(false);
            };
            let item = file_system_bind.get_mut(item_id).unwrap();
            item.get_mut().text = text;
            return Ok(true);
        } else {
            return Err(LuaError::external("Could't find the item"));
        };
    })?;
    lua.globals().set("set_text", lua_set_text)?;

    let lua_get_data = lua.create_function(|_, url: String| {
        if let Ok(data) = blocking::get(url) {
            if let Ok(contents) = data.text() {
                return Ok(Some(contents));
            };
        };
        Ok(None)
    })?;
    lua.globals().set("get_data", lua_get_data)?;

    let lua_get_key_press = lua.create_function(|_, (): ()| {
        let mut stdout = io::stdout().into_raw_mode().unwrap();
        stdout.flush().unwrap();

        let key = io::stdin().keys().next().unwrap().unwrap();
        match key {
            termion::event::Key::Char(char) => Ok(vec![Some(char.to_string()), None]),
            termion::event::Key::Alt(char) => Ok(vec![Some(char.to_string()), Some("Alt".to_string())]),
            termion::event::Key::Ctrl(char) => Ok(vec![Some(char.to_string()), Some("Ctrl".to_string())]),
            termion::event::Key::F(number) => Ok(vec![None, Some(format!("F{number}"))]),
            termion::event::Key::Esc => Ok(vec![None, Some("Esc".to_string())]),
            termion::event::Key::Up => Ok(vec![None, Some("Up".to_string())]),
            termion::event::Key::Down => Ok(vec![None, Some("Down".to_string())]),
            termion::event::Key::Left => Ok(vec![None, Some("Left".to_string())]),
            termion::event::Key::Right => Ok(vec![None, Some("Right".to_string())]),
            termion::event::Key::Backspace => Ok(vec![None, Some("Backspace".to_string())]),
            _ => Ok(vec![None, None]),
        }
    })?;
    lua.globals().set("get_key_press", lua_get_key_press)?;

    let file_system_clone = Arc::clone(file_system);
    let root_clone = root;
    let file_path_clone = file_path.to_string();
    let lua_save_file_system = lua.create_function(move |_, (): ()| {
        let _ = save_file_system(&file_system_clone.lock().unwrap(), root_clone, &file_path_clone);
        Ok(())
    })?;
    lua.globals().set("save_file_system", lua_save_file_system)?;

    let lua_exit_os = lua.create_function(|_, (): ()| -> Result<(), LuaError> {
        std::process::exit(0);
    })?;
    lua.globals().set("exit_os", lua_exit_os)?;

    let _ = lua.globals().set("SafeMode", safe_mode);

    let file_system_clone = Arc::clone(file_system);
    let shell;
    {
        let temp_file_system_clone = file_system_clone.lock().unwrap();
        shell = temp_file_system_clone[get_item(&temp_file_system_clone, vec!["System".to_string(),"Shell.lua".to_string()], &root).unwrap()].get().text.clone();
    }
    lua.load(shell).exec()
}

pub fn format_lua_error(err: &Error) -> String {
    match err {
        Error::CallbackError { traceback, cause, .. } => {
            format!("Lua callback error: {}\nTraceback:\n{}", cause, traceback)
        }
        other => format!("{}", other),
    }
}
