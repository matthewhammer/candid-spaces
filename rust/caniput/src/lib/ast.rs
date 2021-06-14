pub use candid::parser::value::IDLValue as ParsedValue;

use candid::parser::value::IDLField as ParsedField;
use candid::parser::value::IDLArgs as ParsedArgs;
use candid::types::Label as ParsedLabel;

use candid::{Nat, Int};
use candid::{CandidType, Deserialize};

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
                let mut v2 = vec!();
                for v in v1.iter() { v2.push(Value::from(v)) };
                Value::Vec(v2)
            },
            ParsedValue::Variant(vv) => {
                Value::Variant(Box::new(Field::from(&*vv.0)))
            },
            ParsedValue::Record(fs1) => {
                let mut fs2 = vec!();
                for f in fs1.iter() { fs2.push(Field::from(f)) };
                Value::Record(fs2)
            },
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