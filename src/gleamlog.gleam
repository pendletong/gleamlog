import birl.{type Time}
import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/order.{Eq, Gt, Lt}
import gleam/regex
import gleam/string
import gleam/string_builder

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

pub type Config(fmt) {
  Config(
    filter: fn(Log) -> Bool,
    formatter: fn(Log) -> fmt,
    writer: fn(Log) -> Nil,
    immediate: Bool,
    level: LogLevel,
  )
}

pub fn basic() -> Config(String) {
  let c = Config(fn(_l) { True }, basic_formatter, fn(_l) { Nil }, True, Debug)
  Config(..c, filter: basic_filter(c, _), writer: basic_writer(c, _))
}

pub fn main() {
  io.println("Hello from gleamlog!")
  basic()
  |> debug("This {} is a \\{}{} test", [
    Fn(fn() { "Hello" }),
    String("a"),
    Int(123),
    Bool(False),
  ])
}

pub fn debug(config: Config(fmt), log: String, params: List(LogParam)) -> Nil {
  let l = Log(birl.now(), Debug, log, params)
  case config.filter(l) {
    True ->
      case config.immediate {
        True -> {
          config.writer(l)
        }
        False -> Nil
      }
    False -> Nil
  }
}

fn basic_filter(config: Config(fmt), log: Log) -> Bool {
  case check_level(log.level, config.level) {
    Gt | Eq -> True
    _ -> False
  }
}

fn basic_formatter(log: Log) -> String {
  let assert Ok(regex) = regex.from_string("(?<!\\\\)\\{\\}")
  let elements = regex.split(regex, log.log)

  let elen = list.length(elements)

  let plen = list.length(log.params) + 1

  let params =
    case int.compare(elen, plen) {
      Eq -> log.params
      Gt -> {
        list.append(log.params, list.repeat(String("{}"), elen - plen))
      }
      Lt -> {
        list.split(log.params, elen - 1).0
      }
    }
    |> list.map(stringify_param)

  let logtext = string.join(list.interleave([elements, params]), "")

  string_builder.new()
  |> string_builder.append("[")
  |> string_builder.append(log_title(log.level))
  |> string_builder.append("] ")
  |> string_builder.append(format_date(log.date))
  |> string_builder.append(" - ")
  |> string_builder.append(logtext)
  |> string_builder.to_string
}

fn stringify_param(param: LogParam) -> String {
  case param {
    String(s) -> s
    Bool(b) -> bool.to_string(b)
    Int(i) -> int.to_string(i)
    Float(f) -> float.to_string(f)
    List(l) -> "[" <> string.join(l, ",") <> "]"
    Fn(f) -> f()
  }
}

fn format_date(date: Time) -> String {
  let day = birl.get_day(date)
  let time = birl.get_time_of_day(date)

  string_builder.new()
  |> string_builder.append(string.pad_left(int.to_string(day.date), 2, "0"))
  |> string_builder.append(" ")
  |> string_builder.append(birl.string_month(date))
  |> string_builder.append(" ")
  |> string_builder.append(int.to_string(day.year))
  |> string_builder.append(" ")
  |> string_builder.append(string.pad_left(int.to_string(time.hour), 2, "0"))
  |> string_builder.append(":")
  |> string_builder.append(string.pad_left(int.to_string(time.minute), 2, "0"))
  |> string_builder.to_string
}

fn log_title(level: LogLevel) -> String {
  case level {
    Trace -> "Trace"
    Debug -> "Debug"
    Info -> "Info"
    Warn -> "Warn"
    Error -> "Error"
  }
}

fn basic_writer(config: Config(fmt), log: Log) -> Nil {
  io.debug(config.formatter(log))
  Nil
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
