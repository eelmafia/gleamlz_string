import gleam/bit_array
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import internal_lib/lib

pub fn compress_to_uint8(string: String) {
  lib.compress(string)
}

pub fn decompress_from_uint8(bitstr: BitArray) {
  lib.decompress(bitstr)
}

pub fn compress_to_base64(string: String) {
  string
  |> lib.compress
  |> bit_array.base64_encode(True)
}

pub fn decompress_from_base64(string: String) {
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
  |> string.to_graphemes()
  |> list.index_map(fn(x, i) { #(x, i) })
  |> dict.from_list()
  |> lib.decode_base64(string.to_graphemes(string), _, <<>>)
  |> result.try(lib.decompress)
}

pub fn compress_to_encoded_uri(string: String) {
  string
  |> compress_to_base64
  |> string.replace("/", "-")
  |> string.replace("=", "$")
}

pub fn decompress_from_encoded_uri(string: String) {
  string
  |> string.replace("-", "/")
  |> string.replace("$", "=")
  |> decompress_from_base64
}
