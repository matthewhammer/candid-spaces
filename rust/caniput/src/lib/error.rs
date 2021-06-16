//! Errors generated from the mini terminal.

use log::error;

/// Result from mini terminal.
pub type OurResult<X> = Result<X, OurError>;

/// Errors from the tool, or its subcomponents.
#[derive(Debug, Clone)]
pub enum OurError {
    Candid(std::sync::Arc<candid::Error>),
    Agent(), /* Clone => Agent(ic_agent::AgentError) */
    String(String),
    RingKeyRejected(ring::error::KeyRejected),
    RingUnspecified(ring::error::Unspecified),
    FromHexError(hex::FromHexError),
}

impl std::convert::From<hex::FromHexError> for OurError {
    fn from(fhe: hex::FromHexError) -> Self {
        OurError::FromHexError(fhe)
    }
}

impl std::convert::From<ic_agent::AgentError> for OurError {
    fn from(ae: ic_agent::AgentError) -> Self {
        error!("Detected agent error: {:?}", ae);
        /*OurError::Agent(ae)*/
        OurError::Agent()
    }
}

impl std::convert::From<candid::Error> for OurError {
    fn from(e: candid::Error) -> Self {
        OurError::Candid(std::sync::Arc::new(e))
    }
}

impl<T> std::convert::From<std::sync::mpsc::SendError<T>> for OurError {
    fn from(_s: std::sync::mpsc::SendError<T>) -> Self {
        OurError::String("send error".to_string())
    }
}
impl std::convert::From<std::sync::mpsc::RecvError> for OurError {
    fn from(_s: std::sync::mpsc::RecvError) -> Self {
        OurError::String("recv error".to_string())
    }
}
impl std::convert::From<std::io::Error> for OurError {
    fn from(_s: std::io::Error) -> Self {
        OurError::String("IO error".to_string())
    }
}
impl std::convert::From<String> for OurError {
    fn from(s: String) -> Self {
        OurError::String(s)
    }
}
impl std::convert::From<ring::error::KeyRejected> for OurError {
    fn from(r: ring::error::KeyRejected) -> Self {
        OurError::RingKeyRejected(r)
    }
}
impl std::convert::From<ring::error::Unspecified> for OurError {
    fn from(r: ring::error::Unspecified) -> Self {
        OurError::RingUnspecified(r)
    }
}
