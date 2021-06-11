extern crate garcon;
extern crate futures;
extern crate ic_agent;
extern crate ic_types;
extern crate num_traits;
extern crate serde;
#[macro_use]
extern crate log;
extern crate clap;
extern crate env_logger;

extern crate structopt;
use structopt::StructOpt;

use clap::Shell;

use candid::Decode;
use ic_agent::Agent;
use ic_types::Principal;

use candid::Nat;
use chrono::prelude::*;
use std::fs;
use std::io;
use std::sync::mpsc;
use std::time::Duration;
use tokio::task;

use caniput::error::{OurError, OurResult};
use caniput::ast::Value;

/// Answers "From where do we put and get Candid values?"
#[derive(StructOpt, Debug, Clone)]
pub struct There {
    replica_url: String,
    canister_id: String,
}

/// Caniput (Candid data transporter.)
#[derive(StructOpt, Debug, Clone)]
#[structopt(name = "caniput", raw(setting = "clap::AppSettings::DeriveDisplayOrder"))]
pub struct CliOpt {
    /// Trace-level logging (most verbose)
    #[structopt(short = "t", long = "trace-log")]
    pub log_trace: bool,
    /// Debug-level logging (medium verbose)
    #[structopt(short = "d", long = "debug-log")]
    pub log_debug: bool,
    /// Coarse logging information (not verbose)
    #[structopt(short = "L", long = "log")]
    pub log_info: bool,

    pub replica_url: String,

    pub canister_id: String,

    #[structopt(subcommand)]
    pub command: CliCommand,
}

#[derive(StructOpt, Debug, Clone)]
pub enum CliCommand {
    #[structopt(
        name = "completions",
        about = "Generate shell scripts for auto-completions."
    )]
    Completions { shell: Shell },
    #[structopt(name = "text", about = "put a candid value there, expressed here as a text arg.")]
    PutText {
        put_path: String,
        candid_value: String,
    },
}

/// Connection context: IC agent object, for server calls, and configuration info.
pub struct ConnectCtx {
    pub cfg: ConnectCfg,
    pub agent: Agent,
    pub canister_id: Principal,
}

/// Service call requests, expressed as data.
pub enum ServiceCall {
    Put(String, Vec<Value>),
}

/// Connection configuration
#[derive(Debug, Clone)]
pub struct ConnectCfg {
    pub cli_opt: CliOpt,
    pub there: There,
}

fn init_log(level_filter: log::LevelFilter) {
    use env_logger::{Builder, WriteStyle};
    let mut builder = Builder::new();
    builder
        .filter(None, level_filter)
        .write_style(WriteStyle::Always)
        .init();
}

const RETRY_PAUSE: Duration = Duration::from_millis(100);
const REQUEST_TIMEOUT: Duration = Duration::from_secs(60);

async fn create_agent(url: &str) -> OurResult<Agent> {
    //use ring::signature::Ed25519KeyPair;
    use ring::rand::SystemRandom;

    // to do -- read identity from a file
    let rng = SystemRandom::new();
    let pkcs8_bytes = ring::signature::Ed25519KeyPair::generate_pkcs8(&rng)?;
    let key_pair = ring::signature::Ed25519KeyPair::from_pkcs8(pkcs8_bytes.as_ref())?;
    let ident = ic_agent::identity::BasicIdentity::from_key_pair(key_pair);
    let agent = Agent::builder()
        .with_url(format!("http://{}", url))
        .with_identity(ident)
        .build()?;
    if true { // to do -- CLI switch.
        agent.fetch_root_key().await?;
    }
    Ok(agent)
}

async fn service_call(ctx: &ConnectCtx,
                      call: &ServiceCall) -> OurResult<()> {
    let prefix = match &call {
        ServiceCall::Put(_, _) => "Service (put):",
    };
    let delay = garcon::Delay::builder()
        .throttle(RETRY_PAUSE)
        .timeout(REQUEST_TIMEOUT)
        .build();
    let timestamp = std::time::SystemTime::now();
    let arg_bytes = match call {
        ServiceCall::Put(path, vals) => candid::encode_args((path, vals)).unwrap(),
    };
    info!(
        "{}: Encoded argument via Candid; Arg size {:?} bytes",
        prefix,
        arg_bytes.len()
    );
    info!("{}: Awaiting response from service...", prefix);
    // do an update or query call, based on the ServiceCall case:
    let blob_res : Option<Vec<u8>> = match call {
        ServiceCall::Put(_, _) => {
            // to do
            unimplemented!()
        },
    };
    let elapsed = timestamp.elapsed().unwrap();
    if let Some(blob_res) = blob_res {
        info!(
            "{}: Ok: Response size {:?} bytes; elapsed time {:?}",
            prefix,
            blob_res.len(),
            elapsed
        );
        match call {
            ServiceCall::Put(_, _) => {
                // to do
                unimplemented!()
            },
        }
    }
    Ok(())
}

async fn run(cfg: ConnectCfg) -> OurResult<()> {

    let canister_id = Principal::from_text(cfg.there.canister_id.clone()).unwrap();
    let agent = create_agent(&cfg.there.replica_url).await?;

    info!("Connecting to IC canister: {}", canister_id);
    let ctx = ConnectCtx {
        cfg,
        canister_id,
        agent,
    };
    trace!("{:?}", ctx.cfg);

    unimplemented!();
    Ok(())
}

#[tokio::main]
async fn main() -> OurResult<()> {
    let cli_opt = CliOpt::from_args();
    init_log(
        match (cli_opt.log_trace, cli_opt.log_debug, cli_opt.log_info) {
            (true, _, _) => log::LevelFilter::Trace,
            (_, true, _) => log::LevelFilter::Debug,
            (_, _, true) => log::LevelFilter::Info,
            (_, _, _) => log::LevelFilter::Warn,
        },
    );
    info!("Evaluating CLI command: {:?} ...", &cli_opt.command);
    let c = cli_opt.command.clone();
    let () = match c {
        CliCommand::Completions { shell: s } => {
            // see also: https://clap.rs/effortless-auto-completion/
            CliOpt::clap().gen_completions_to("caniput", s, &mut io::stdout());
            info!("done");
        }
        CliCommand::PutText {
            put_path,
            candid_value,
        } => {
            unimplemented!()
        },
    };
    Ok(())
}
