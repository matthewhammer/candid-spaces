use candid::parser::value::IDLValue as ParsedValue;
use candid::parser::value::IDLField as ParsedField;
use candid::parser::value::IDLArgs as ParsedArgs;
use candid::types::{Label};
use candid::{Nat, Int, Empty};

// From 
// https://github.com/dfinity/candid/blob/bb84807217dad6e69c78de0403030e232efaa43e/rust/candid/src/parser/value.rs#L13
#[derive(PartialEq, Clone)]
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
}

#[derive(PartialEq, Clone)]
pub struct Field {
    pub id: Label,
    pub val: Value,
}

#[derive(PartialEq, Clone)]
pub struct Args {
    pub args: Vec<Value>,
}

impl From<&ParsedArgs> for Args {
    fn from(a: &ParsedArgs) -> Args {
        let mut v2 = vec!();
        for v in a.args.iter() {
            v2.push(Value::from(v))
        };
        Args{ args: v2 }
    }
}

impl From<&ParsedField> for Field {
    fn from(f: &ParsedField) -> Field {
        Field{
            id: f.id.clone(),
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
/*
            Float64(f64),
            Opt(Box<IDLValue>),
            Vec(Vec<IDLValue>),
            Record(Vec<IDLField>),
            Variant(Box<IDLField>, u64), // u64 represents the index from the type, defaults to 0 when parsing
            Principal(crate::Principal),
            Service(crate::Principal),
            Func(crate::Principal, String),
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
*/
            _ => unimplemented!()
        }
    }
}
