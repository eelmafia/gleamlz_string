import gleam/bit_array
import gleam/erlang/atom
import gleam/list
import gleam/string
import gleamlz_string
import gleeunit
import gleeunit/should
import helpers/test_helpers

pub fn main() {
  gleeunit.main()
}

//gleeunit test functions end in `_test`

pub fn known_compression_test() {
  gleamlz_string.compress_to_uint8("hello, i am a 猫")
  |> should.equal(<<
    5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144,
    0,
  >>)
}

pub fn known_decompression_test() {
  gleamlz_string.decompress_from_uint8(<<
    5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144,
    0,
  >>)
  |> should.equal(Ok("hello, i am a 猫"))
}

pub fn every_utf8_char_test_() {
  let assert Ok(timeout) = atom.from_string("timeout")
  #(timeout, 20.0, [
    fn() {
      let allutf8chars = test_helpers.all_utf8_chars()

      gleamlz_string.compress_to_uint8(allutf8chars)
      |> gleamlz_string.decompress_from_uint8
      |> should.equal(Ok(allutf8chars))
    },
  ])
}

pub fn repeated_single_byte_test_() {
  let assert Ok(timeout) = atom.from_string("timeout")
  #(timeout, 20.0, [
    fn() {
      let range = list.range(1, 2000)
      list.each(range, fn(x) {
        let string = string.repeat("a", x)
        gleamlz_string.compress_to_uint8(string)
        |> gleamlz_string.decompress_from_uint8
        |> should.equal(Ok(string))
      })
    },
  ])
}

pub fn repeated_double_byte_test_() {
  let assert Ok(timeout) = atom.from_string("timeout")
  #(timeout, 20.0, [
    fn() {
      let range = list.range(1, 2000)
      list.each(range, fn(x) {
        let string = string.repeat("猫", x)
        gleamlz_string.compress_to_uint8(string)
        |> gleamlz_string.decompress_from_uint8
        |> should.equal(Ok(string))
      })
    },
  ])
}

pub fn high_entropy_string_test_() {
  let assert Ok(timeout) = atom.from_string("timeout")
  #(timeout, 40.0, [
    fn() {
      let range = list.range(1, 2000)
      list.each(range, fn(_x) {
        let str = test_helpers.random_string(1000)

        gleamlz_string.compress_to_uint8(str)
        |> gleamlz_string.decompress_from_uint8
        |> should.equal(Ok(str))
      })
    },
  ])
}

pub fn large_low_entropy_string_test_() {
  let assert Ok(timeout) = atom.from_string("timeout")
  #(timeout, 40.0, [
    fn() {
      let str =
        bit_array.base16_encode(test_helpers.generate_random_bytes(1_000_000))

      gleamlz_string.compress_to_uint8(str)
      |> gleamlz_string.decompress_from_uint8
      |> should.equal(Ok(str))
    },
  ])
}
