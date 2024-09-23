import gleam/int
import gleam/result
import gleam/string

pub fn random_string(size: Int) {
  random_string_tco([], size)
  |> string.from_utf_codepoints
}

fn random_string_tco(list: List(UtfCodepoint), n: Int) {
  case n {
    0 -> list
    n -> random_string_tco([random_utf8(), ..list], n - 1)
  }
}

fn random_utf8() {
  result.lazy_unwrap(
    {
      random_int_in_range()
      |> string.utf_codepoint()
    },
    fn() { random_utf8() },
  )
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
