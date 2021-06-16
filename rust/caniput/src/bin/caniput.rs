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

//use candid::Decode;
use ic_agent::Agent;
use ic_types::Principal;

use std::io;
use std::time::Duration;

use caniput::error::{OurResult};
use caniput::ast::{ParsedValue, Value};

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

    /// Username
    #[structopt(short = "u", long = "username", default_value="guest")]
    pub username: String,

    /// Replica URL
    #[structopt(short = "r", long = "replica", default_value="http://127.0.0.1:8000")]
    pub replica_url: String,

    /// Canister ID
    #[structopt(short = "c", long = "canister", default_value="rrkah-fqaaa-aaaaa-aaaaq-cai")]
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
    #[structopt(name = "value", about = "put a candid value there, expressed here as a text arg.")]
    PutValue {
        put_path: String,
        candid_value: String,
    },
    #[structopt(name = "text", about = "put a text value there, expressed here as a text arg.")]
    PutText {
        put_path: String,
        candid_text: String,
    },
}

/// Connection context: IC agent object, for server calls, and configuration info.
pub struct ConnectCtx {
    pub cli_opt: CliOpt,
    pub agent: Agent,
    pub canister_id: Principal,
}

/// Service call requests, expressed as data.
pub enum ServiceCall {
    Put(Vec<String>, Vec<Value>),
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
    info!("creating agent.");

    // to do -- read identity from a file
    let rng = SystemRandom::new();
    let pkcs8_bytes = ring::signature::Ed25519KeyPair::generate_pkcs8(&rng)?;
    let key_pair = ring::signature::Ed25519KeyPair::from_pkcs8(pkcs8_bytes.as_ref())?;
    let ident = ic_agent::identity::BasicIdentity::from_key_pair(key_pair);
    let agent = Agent::builder()
        .with_url(url)
        .with_identity(ident)
        .build()?;
    info!("built agent.");
    if true { // to do -- CLI switch.
        agent.fetch_root_key().await?;
    }
    info!("got root key.");
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
    let user = ctx.cli_opt.username.clone();
    let arg_bytes = match call {
        ServiceCall::Put(path, vals) => candid::encode_args((user, path, vals)).unwrap(),
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
            let resp = ctx
                .agent
                .update(&ctx.canister_id, "put")
                .with_arg(arg_bytes)
                .call_and_wait(delay)
                .await?;
            Some(resp)
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
        let result_flag : (Option<()>,) = candid::decode_args(&blob_res)?;
        match result_flag {
            (None,) => error!("Failure to put."),
            (Some(()),) => info!("Put value successfully."),
        };
        Ok(())
    } else {
        error!("{}: Error response. Elapsed time {:?}.",
               prefix,
               elapsed);
        Ok(())
    }
}

#[tokio::main]
async fn main() -> OurResult<()> {
    info!("Starting...");
    let cli_opt = CliOpt::from_args();
    let cc = {
        let cli_opt = cli_opt.clone();
        let canister_id = Principal::from_text(&cli_opt.canister_id).unwrap();
        let agent = create_agent(&cli_opt.replica_url).await?;
        ConnectCtx {
            cli_opt,
            canister_id,
            agent,
        }
    };
    info!("Init log...");
    init_log(
        match (cli_opt.log_trace, cli_opt.log_debug, cli_opt.log_info) {
            (true, _, _) => log::LevelFilter::Trace,
            (_, true, _) => log::LevelFilter::Debug,
            (_, _, true) => log::LevelFilter::Info,
            (_, _, _) => log::LevelFilter::Warn,
        },
    );
    info!("Evaluating CLI command: {:?} ...", &cli_opt.command);
    let () = match cli_opt.command {
        CliCommand::Completions { shell: s } => {
            // see also: https://clap.rs/effortless-auto-completion/
            CliOpt::clap().gen_completions_to("caniput", s, &mut io::stdout());
            info!("done");
        },
        CliCommand::PutValue {
            put_path,
            candid_value,
        } => {
            let parsed_val : ParsedValue = candid_value.parse()?;
            let ast = Value::from(&parsed_val);
            service_call(&cc, &ServiceCall::Put(vec!(put_path), vec!(ast))).await?;
        },
        CliCommand::PutText {
            put_path,
            candid_text,
        } => {
            let ast = Value::Text(candid_text.clone());
            service_call(&cc, &ServiceCall::Put(vec!(put_path), vec!(ast))).await?;
        },
    };
    Ok(())
}
