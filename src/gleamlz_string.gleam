import gleam/bit_array
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import internal_lib/lib.{type DecompressError}

/// Compress a string to a BitArray
/// ## Example
/// ```gleam
/// let compressed = compress_to_uint8(string: "Hello World")
/// ```
///
pub fn compress_to_uint8(string: String) -> BitArray {
  lib.compress(string)
}

/// Decompress an lz-string BitArray back to the original UTF16 string
/// ## Example
/// ```gleam
/// let assert Ok(decompressed) = decompress_from_uint8(bits: <<5, 132, 178, 0>>)
/// ```
///
pub fn decompress_from_uint8(bits: BitArray) -> Result(String, DecompressError) {
  lib.decompress(bits)
}

/// Compress a string into an ASCII base64 encoded representation
/// ## Example
/// ```gleam
/// let compressed = compress_to_base64(string: "Hello World")
/// ```
///
pub fn compress_to_base64(string: String) -> String {
  string
  |> lib.compress
  |> bit_array.base64_encode(True)
}

/// Decompress an lz-string base64 string back to the original UTF16 string
/// ## Example
/// ```gleam
/// let assert Ok(decompressed) = decompress_from_base64(base64_string: "BYUwNmD2A0AECWsCGBbZtDUzkAA=")
/// ```
///
pub fn decompress_from_base64(
  base64_string: String,
) -> Result(String, DecompressError) {
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
  |> string.to_graphemes()
  |> list.index_map(fn(x, i) { #(x, i) })
  |> dict.from_list()
  |> lib.decode_base64(string.to_graphemes(base64_string), _, <<>>)
  |> result.try(lib.decompress)
}

/// Compress a string into ASCII representing the original string with a few changes to make it URI safe
/// ## Example
/// ```gleam
/// let compressed = compress_to_encoded_uri(string: "Hello World")
/// ```
///
pub fn compress_to_encoded_uri(string: String) -> String {
  string
  |> compress_to_base64
  |> string.replace("/", "-")
  |> string.replace("=", "$")
}

/// Decompress an lz-string URI string back to the original UTF16 string
/// ## Example
/// ```gleam
/// let assert Ok(decompressed) = decompress_from_encoded_uri(uri_string: "BYUwNmD2A0AECWsCGBbZtDUzkAA$")
/// ```
///
pub fn decompress_from_encoded_uri(
  uri_string: String,
) -> Result(String, DecompressError) {
  uri_string
  |> string.replace("-", "/")
  |> string.replace("$", "=")
  |> decompress_from_base64
}
