import gleam/bit_array
import gleam/erlang/atom
import gleam/list
import gleam/string
import gleamlz_string
import gleeunit
import gleeunit/should
import helpers/test_helpers

const known_string = "hello, i am a 猫"

pub fn main() {
  gleeunit.main()
}

//gleeunit test functions end in `_test`

pub fn known_compression_test() {
  gleamlz_string.compress_to_uint8(known_string)
  |> should.equal(<<
    5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144,
    0,
  >>)

  gleamlz_string.compress_to_base64(known_string)
  |> should.equal("BYUwNmD2A0AECWsCGBbZtDUzkAA=")

  gleamlz_string.compress_to_encoded_uri(known_string)
  |> should.equal("BYUwNmD2A0AECWsCGBbZtDUzkAA$")
}

pub fn known_decompression_test() {
  gleamlz_string.decompress_from_uint8(<<
    5, 133, 48, 54, 96, 246, 3, 64, 4, 9, 107, 2, 24, 22, 217, 180, 53, 51, 144,
    0,
  >>)
  |> should.equal(Ok(known_string))

  gleamlz_string.decompress_from_base64("BYUwNmD2A0AECWsCGBbZtDUzkAA=")
  |> should.equal(Ok(known_string))

  gleamlz_string.decompress_from_encoded_uri("BYUwNmD2A0AECWsCGBbZtDUzkAA$")
  |> should.equal(Ok(known_string))
}

pub fn every_utf8_char_test_() {
  let assert Ok(timeout) = atom.from_string("timeout")
  #(timeout, 60.0, [
    fn() {
      let allutf8chars = test_helpers.all_utf8_chars()

      gleamlz_string.compress_to_uint8(allutf8chars)
      |> gleamlz_string.decompress_from_uint8
      |> should.equal(Ok(allutf8chars))

      gleamlz_string.compress_to_base64(allutf8chars)
      |> gleamlz_string.decompress_from_base64
      |> should.equal(Ok(allutf8chars))

      gleamlz_string.compress_to_encoded_uri(allutf8chars)
      |> gleamlz_string.decompress_from_encoded_uri
      |> should.equal(Ok(allutf8chars))
    },
  ])
}

pub fn repeated_single_byte_test_() {
  let assert Ok(timeout) = atom.from_string("timeout")
  #(timeout, 60.0, [
    fn() {
      let range = list.range(1, 2000)
      list.each(range, fn(x) {
        let string = string.repeat("a", x)

        gleamlz_string.compress_to_uint8(string)
        |> gleamlz_string.decompress_from_uint8
        |> should.equal(Ok(string))

        gleamlz_string.compress_to_base64(string)
        |> gleamlz_string.decompress_from_base64
        |> should.equal(Ok(string))

        gleamlz_string.compress_to_encoded_uri(string)
        |> gleamlz_string.decompress_from_encoded_uri
        |> should.equal(Ok(string))
      })
    },
  ])
}

pub fn repeated_double_byte_test_() {
  let assert Ok(timeout) = atom.from_string("timeout")
  #(timeout, 60.0, [
    fn() {
      let range = list.range(1, 2000)
      list.each(range, fn(x) {
        let string = string.repeat("猫", x)

        gleamlz_string.compress_to_uint8(string)
        |> gleamlz_string.decompress_from_uint8
        |> should.equal(Ok(string))

        gleamlz_string.compress_to_base64(string)
        |> gleamlz_string.decompress_from_base64
        |> should.equal(Ok(string))

        gleamlz_string.compress_to_encoded_uri(string)
        |> gleamlz_string.decompress_from_encoded_uri
        |> should.equal(Ok(string))
      })
    },
  ])
}

pub fn high_entropy_string_test_() {
  let assert Ok(timeout) = atom.from_string("timeout")
  #(timeout, 300.0, [
    fn() {
      let range = list.range(1, 2000)
      list.each(range, fn(_x) {
        let str = test_helpers.random_string(1000)

        gleamlz_string.compress_to_uint8(str)
        |> gleamlz_string.decompress_from_uint8
        |> should.equal(Ok(str))

        gleamlz_string.compress_to_base64(str)
        |> gleamlz_string.decompress_from_base64
        |> should.equal(Ok(str))

        gleamlz_string.compress_to_encoded_uri(str)
        |> gleamlz_string.decompress_from_encoded_uri
        |> should.equal(Ok(str))
      })
    },
  ])
}

pub fn large_low_entropy_string_test_() {
  let assert Ok(timeout) = atom.from_string("timeout")
  #(timeout, 60.0, [
    fn() {
      let str =
        bit_array.base16_encode(test_helpers.generate_random_bytes(1_000_000))

      gleamlz_string.compress_to_uint8(str)
      |> gleamlz_string.decompress_from_uint8
      |> should.equal(Ok(str))

      gleamlz_string.compress_to_base64(str)
      |> gleamlz_string.decompress_from_base64
      |> should.equal(Ok(str))

      gleamlz_string.compress_to_encoded_uri(str)
      |> gleamlz_string.decompress_from_encoded_uri
      |> should.equal(Ok(str))
    },
  ])
}
