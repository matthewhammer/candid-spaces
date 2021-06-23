pub use candid::parser::value::IDLValue as ParsedValue;

use candid::parser::value::IDLArgs as ParsedArgs;
use candid::parser::value::IDLField as ParsedField;
use candid::types::Label as ParsedLabel;

use candid::{CandidType, Deserialize};
use candid::{Int, Nat};

use log::{debug, info};

use crate::error::*;

#[derive(PartialEq, Clone, CandidType, Deserialize)]
pub struct NameFile {
    name: String,
    file: File,
}

#[derive(PartialEq, Clone, CandidType, Deserialize)]
pub enum File {
    Directory(Vec<NameFile>),
    Text(String),
    Binary(Vec<u8>),
    Value(Value),
    Args(Args),
}

// From
// https://github.com/dfinity/candid/blob/bb84807217dad6e69c78de0403030e232efaa43e/rust/candid/src/parser/value.rs#L13
#[derive(PartialEq, Clone, CandidType, Deserialize)]
pub enum Value {
    Bool(bool),
    Null,
    Text(String),
    Number(String), // Undetermined number type
    Float64(f64),
    Opt(Box<Value>),
    Vec(Vec<Value>),
    Record(Vec<Field>),
    Variant(Box<Field>),
    Principal(candid::Principal),
    Service(candid::Principal),
    Func(candid::Principal, String),
    // The following values can only be generated with type annotation
    None,
    Int(Int),
    Nat(Nat),
    Nat8(u8),
    Nat16(u16),
    Nat32(u32),
    Nat64(u64),
    Int8(i8),
    Int16(i16),
    Int32(i32),
    Int64(i64),
    Float32(f32),
    Reserved,
    /// Extension: Inject local filesystem structure, mixed with candid value structure.
    File(Box<File>),
}

#[derive(PartialEq, Debug, Clone, CandidType, Deserialize)]
pub enum Label {
    Id(u32),
    Named(String),
    Unnamed(u32),
}

#[derive(PartialEq, Clone, CandidType, Deserialize)]
pub struct Field {
    pub id: Label,
    pub val: Value,
}

#[derive(PartialEq, Clone, CandidType, Deserialize)]
pub struct Args {
    pub args: Vec<Value>,
}

impl From<&ParsedLabel> for Label {
    fn from(l: &ParsedLabel) -> Label {
        match l {
            ParsedLabel::Id(n) => Label::Id(*n),
            ParsedLabel::Named(n) => Label::Named(n.clone()),
            ParsedLabel::Unnamed(n) => Label::Unnamed(*n),
        }
    }
}

impl From<&ParsedArgs> for Args {
    fn from(a: &ParsedArgs) -> Args {
        let mut v2 = vec![];
        for v in a.args.iter() {
            v2.push(Value::from(v))
        }
        Args { args: v2 }
    }
}

impl From<&ParsedField> for Field {
    fn from(f: &ParsedField) -> Field {
        Field {
            id: Label::from(&f.id),
            val: Value::from(&f.val),
        }
    }
}

impl From<&ParsedValue> for Value {
    fn from(v: &ParsedValue) -> Value {
        match v {
            ParsedValue::Bool(b) => Value::Bool(*b),
            ParsedValue::Null => Value::Null,
            ParsedValue::Text(s) => Value::Text(s.clone()),
            ParsedValue::Number(s) => Value::Number(s.clone()),
            ParsedValue::Float64(f) => Value::Float64(*f),
            ParsedValue::Opt(v) => Value::Opt(Box::new(Value::from(&**v))),
            ParsedValue::Vec(v1) => {
                let mut v2 = vec![];
                for v in v1.iter() {
                    v2.push(Value::from(v))
                }
                Value::Vec(v2)
            }
            ParsedValue::Variant(vv) => Value::Variant(Box::new(Field::from(&*vv.0))),
            ParsedValue::Record(fs1) => {
                let mut fs2 = vec![];
                for f in fs1.iter() {
                    fs2.push(Field::from(f))
                }
                Value::Record(fs2)
            }
            ParsedValue::Principal(p) => Value::Principal(p.clone()),
            ParsedValue::Service(p) => Value::Service(p.clone()),
            ParsedValue::Func(p, s) => Value::Func(p.clone(), s.clone()),
            ParsedValue::None => Value::None,
            ParsedValue::Int(i) => Value::Int(i.clone()),
            ParsedValue::Nat(n) => Value::Nat(n.clone()),
            ParsedValue::Nat8(n) => Value::Nat8(n.clone()),
            ParsedValue::Nat16(n) => Value::Nat16(n.clone()),
            ParsedValue::Nat32(n) => Value::Nat32(n.clone()),
            ParsedValue::Nat64(n) => Value::Nat64(n.clone()),
            ParsedValue::Int8(i) => Value::Int8(i.clone()),
            ParsedValue::Int16(i) => Value::Int16(i.clone()),
            ParsedValue::Int32(i) => Value::Int32(i.clone()),
            ParsedValue::Int64(i) => Value::Int64(i.clone()),
            ParsedValue::Float32(f) => Value::Float32(f.clone()),
            ParsedValue::Reserved => Value::Reserved,
        }
    }
}

fn trim_newline(s: &mut String) {
    if s.ends_with('\n') {
        s.pop();
        if s.ends_with('\r') {
            s.pop();
        }
    }
}

/// Read filesystem starting at `path`, and construct a `File`.
pub fn file_of_path(path: &std::path::Path) -> OurResult<File> {
    info!("Reading path {:?}", path);
    if path.is_dir() {
        let mut name_files = vec![];
        for entry in std::fs::read_dir(path)? {
            let entry = entry?;
            let name = entry.file_name().to_str().unwrap().to_string();
            let file = file_of_path(&entry.path())?;
            name_files.push(NameFile { name, file });
        }
        Ok(File::Directory(name_files))
    } else {
        if let Ok(mut s) = std::fs::read_to_string(path) {
            trim_newline(&mut s);
            // text file
            let pv: Result<ParsedValue, _> = s.parse();
            if let Ok(v) = pv {
                debug!("{:?}: Text file: Parsed value {}", path, v);
                Ok(File::Value(Value::from(&v)))
            } else {
                let pa: Result<ParsedArgs, _> = s.parse();
                if let Ok(a) = pa {
                    debug!("{:?}: Text file: Parsed args {}", path, a);
                    Ok(File::Args(Args::from(&a)))
                } else {
                    if let Ok(bytes) = hex::decode(&s) {
                        debug!("{:?}: Hex file ...", path);
                        let pa: Result<ParsedArgs, _> = ParsedArgs::from_bytes(&bytes);
                        if let Ok(a) = pa {
                            debug!("{:?}: Hex file: Parsed args {}", path, a);
                            Ok(File::Args(Args::from(&a)))
                        } else {
                            if let Ok(v) = pv {
                                debug!("{:?}: Hex file: Parsed value {}", path, v);
                                Ok(File::Value(Value::from(&v)))
                            } else {
                                debug!("{:?}: Hex file with uninterpreted content.", path);
                                Ok(File::Binary(bytes))
                            }
                        }
                    } else {
                        debug!("{:?}: Text file with uninterpreted content.", path);
                        Ok(File::Text(s))
                    }
                }
            }
        } else {
            // binary file.
            let bytes = std::fs::read(path)?;
            let mut de = candid::de::IDLDeserialize::new(&bytes)?;
            if let Ok(v) = de.get_value::<ParsedValue>() {
                debug!("{:?}: Binary file: Parsed value {}", path, v);
                Ok(File::Value(Value::from(&v)))
            } else {
                let pa: Result<ParsedArgs, _> = ParsedArgs::from_bytes(&bytes);
                if let Ok(a) = pa {
                    debug!("{:?}: Binary file: Parsed args {}", path, a);
                    Ok(File::Args(Args::from(&a)))
                } else {
                    debug!("{:?}: Binary file with uninterpreted content.", path);
                    Ok(File::Binary(bytes))
                }
            }
        }
    }
}
