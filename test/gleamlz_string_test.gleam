import file_streams/file_stream.{type FileStream}
import gleam/bit_array
import gleam/erlang/atom
import gleam/list
import gleam/result
import gleam/string
import gleamlz_string
import gleeunit
import gleeunit/should
import helpers/test_helpers

type Mode {
  Uint8
  Base64
  URI
}

const known_string = "hello, i am a 猫"

const filename = "output.bin"

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
  #(timeout, 300.0, [
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

pub fn invalid_input_test() {
  gleamlz_string.decompress_from_uint8(<<5>>)
  |> should.be_error

  gleamlz_string.decompress_from_base64(known_string)
  |> should.be_error

  gleamlz_string.decompress_from_encoded_uri(known_string)
  |> should.be_error
}

//Tests with the OG javascript library output

pub fn js_lib_test_() {
  let assert Ok(timeout) = atom.from_string("timeout")
  #(timeout, 300.0, [
    fn() {
      let assert Ok(stream) = file_stream.open_read(filename)
      //Test 2 known strings
      js_test_known(stream)
      |> should.be_ok

      //1000 strings of 1_000 chars each
      js_test_random_uint8(stream, 1000)
      |> should.be_ok

      js_test_random_base64(stream, 1000)
      |> should.be_ok

      js_test_random_uri(stream, 1000)
      |> should.be_ok

      //1 string 1_000_000 chars
      js_test_random_uint8(stream, 1)
      |> should.be_ok

      js_test_random_base64(stream, 1)
      |> should.be_ok

      js_test_random_uri(stream, 1)
      |> should.be_ok

      //every single utf8 character
      js_test_all_utf8_uint8(stream)
      |> should.be_ok

      js_test_all_utf8_base64(stream)
      |> should.be_ok
      |> should.be_ok

      js_test_all_utf8_uri(stream)
      |> should.be_ok
      |> should.be_ok

      let assert Ok(Nil) = file_stream.close(stream)
    },
  ])
}

fn js_test_known(stream: FileStream) {
  [
    "hello, i am a 猫",
    "今日は 今日は 今日は 今日は 今日は 今日は",
  ]
  |> list.try_each(fn(string) { js_compress_vs_known(stream, string) })
}

fn js_test_random_uint8(fstream: FileStream, n: Int) {
  list.range(0, n)
  |> list.try_each(fn(_x) { js_decompress_vs_unknown(fstream, Uint8) })
}

fn js_test_random_base64(fstream: FileStream, n: Int) {
  list.range(0, n)
  |> list.try_each(fn(_x) { js_decompress_vs_unknown(fstream, Base64) })
}

pub fn js_test_random_uri(fstream: FileStream, n: Int) {
  list.range(0, n)
  |> list.try_each(fn(_x) { js_decompress_vs_unknown(fstream, URI) })
}

fn js_test_all_utf8_uint8(fstream: FileStream) {
  let allutf8chars = test_helpers.all_utf8_chars()

  use #(_input_str, output_str) <- result.map(read_js_input_output(fstream))

  output_str
  |> gleamlz_string.decompress_from_uint8()
  |> should.equal(Ok(allutf8chars))
}

fn js_test_all_utf8_base64(fstream: FileStream) {
  let allutf8chars = test_helpers.all_utf8_chars()
  js_decompress_vs_known(fstream, allutf8chars, Base64)
}

fn js_test_all_utf8_uri(fstream: FileStream) {
  let allutf8chars = test_helpers.all_utf8_chars()
  js_decompress_vs_known(fstream, allutf8chars, URI)
}

//Compress a known string and match the JS output for the same
fn js_compress_vs_known(fstream: FileStream, known_string: String) {
  result.map(read_js_input_output(fstream), fn(result) {
    let compressed = gleamlz_string.compress_to_uint8(known_string)
    compressed
    |> should.equal(result.1)

    compressed
    |> should.not_equal(<<>>)
  })
}

fn js_decompress_vs_known(fstream: FileStream, known_string: String, mode: Mode) {
  use result <- result.map(read_js_input_output(fstream))
  use output_str <- result.map(bit_array.to_string(result.1))
  case mode {
    Uint8 -> {
      gleamlz_string.decompress_from_uint8(result.1)
      |> should.equal(Ok(known_string))
    }
    Base64 -> {
      gleamlz_string.decompress_from_base64(output_str)
      |> should.equal(Ok(known_string))
    }
    URI -> {
      gleamlz_string.decompress_from_encoded_uri(output_str)
      |> should.equal(Ok(known_string))
    }
  }
}

fn js_decompress_vs_unknown(fstream: FileStream, mode: Mode) {
  use result <- result.map(read_js_input_output(fstream))
  use input_str <- result.map(bit_array.to_string(result.0))
  use output_str <- result.map(bit_array.to_string(result.1))

  case mode {
    Uint8 -> {
      gleamlz_string.decompress_from_uint8(result.1)
      |> should.equal(Ok(input_str))
    }
    Base64 -> {
      gleamlz_string.decompress_from_base64(output_str)
      |> should.equal(Ok(input_str))
    }
    URI -> {
      gleamlz_string.decompress_from_encoded_uri(output_str)
      |> should.equal(Ok(input_str))
    }
  }
}

fn read_js_input_output(stream: FileStream) {
  use input_size <- result.try(file_stream.read_uint32_le(stream))
  use str <- result.try(file_stream.read_bytes(stream, input_size))
  use output_size <- result.try(file_stream.read_uint32_le(stream))
  use js_compressed_string <- result.map(file_stream.read_bytes(
    stream,
    output_size,
  ))
  #(str, js_compressed_string)
}
