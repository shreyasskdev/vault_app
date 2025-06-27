use core::fmt;

pub enum VaultError {
    Error(String),
    IncorrectPassword,
}

impl fmt::Display for VaultError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            VaultError::IncorrectPassword => write!(f, "Incorrect password provided."),
            VaultError::Error(s) => write!(f, "{}", s),
        }
    }
}
