import gleam/bit_array
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn all_utf8_chars() -> String {
  let stringlist =
    list.concat([list.range(0, 55_295), list.range(57_344, 65_533)])
    |> list.map(fn(x) { string.utf_codepoint(x) })
    |> result.values
    |> string.from_utf_codepoints

  let assert Ok(first) = bit_array.to_string(<<239, 191, 190>>)
  let assert Ok(second) = bit_array.to_string(<<239, 191, 191>>)

  stringlist <> first <> second
}

pub fn random_string(size: Int) {
  random_string_tco("", size)
}

fn random_string_tco(str: String, n: Int) {
  case n {
    0 -> str
    _ -> random_string_tco(str <> random_utf8_char(), n - 1)
  }
}

fn random_utf8_char() {
  let random = case random_int_in_range() {
    //these 2 noncharacter codepoints arent recognized as codepoints
    65_535 -> {
      bit_array.to_string(<<239, 191, 191>>)
    }
    65_534 -> {
      bit_array.to_string(<<239, 191, 190>>)
    }
    other -> {
      case string.utf_codepoint(other) {
        Ok(codepoint) -> bit_array.to_string(<<codepoint:utf8_codepoint>>)
        _ -> panic as "Unable to generate UTF8 char in test"
      }
    }
  }
  result.lazy_unwrap(random, fn() { random_utf8_char() })
}

fn random_int_in_range() {
  let n = int.random(65_535)

  case n <= 55_295 || n >= 57_344 {
    True -> n
    _ -> random_int_in_range()
  }
}

pub fn generate_random_bytes(n: Int) {
  generate_random_bytes_tco(n, <<>>)
}

fn generate_random_bytes_tco(n: Int, bitstring: BitArray) {
  case n {
    0 -> bitstring
    _ -> {
      generate_random_bytes_tco(n - 1, <<
        bitstring:bits,
        <<int.random(255)>>:bits,
      >>)
    }
  }
}
