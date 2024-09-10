import birl.{type Time}
import gleam/int
import gleam/io
import gleam/order.{Eq, Gt, Lt}

pub type LogLevel {
  Trace
  Debug
  Info
  Warn
  Error
}

pub type LogParam {
  Bool(b: Bool)
  Int(i: Int)
  Float(f: Float)
  String(s: String)
  List(l: List(String))
  Fn(f: fn() -> String)
}

pub type Log {
  Log(date: Time, level: LogLevel, log: String, params: List(LogParam))
}

pub type Config {
  Config(
    filter: fn(Log) -> Bool,
    formatter: fn(Log) -> String,
    writer: fn(Log) -> Nil,
    level: LogLevel,
  )
}

pub fn main() {
  io.println("Hello from gleamlog!")
}

fn basic_filter(config: Config, log: Log) -> Bool {
  case check_level(log.level, config.level) {
    Gt | Eq -> True
    _ -> False
  }
}

fn level(level: LogLevel) -> Int {
  case level {
    Error -> 5
    Warn -> 4
    Info -> 3
    Debug -> 2
    Trace -> 1
  }
}

fn check_level(log: LogLevel, current: LogLevel) {
  int.compare(level(log), level(current))
}
