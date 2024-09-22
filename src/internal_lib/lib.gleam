import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/int
import gleam/string

pub type DecodeType {
  Char(#(BitArray, BitArray, Dict(Int, BitArray)))
  Index(#(Int, BitArray))
  EOF
}

pub fn decode_base64(
  string: String,
  key_dict: Dict(String, Int),
  bitstring: BitArray,
) {
  case string.length(string) {
    0 -> bitstring
    _ -> {
      let assert Ok(#(char, rest)) = string.pop_grapheme(string)
      let assert Ok(num) = dict.get(key_dict, char)
      decode_base64(
        rest,
        key_dict,
        bit_array.append(bitstring, <<num:size(6)>>),
      )
    }
  }
}

pub fn compress(string: String) {
  case string {
    "" -> <<"":utf8>>
    _ -> {
      let bitstring =
        string.to_utf_codepoints(string)
        |> compress_string("", _, dict.new(), <<>>)

      let padding_bits = 16 - { { bitstring |> bit_size(0) } % 16 }
      <<bitstring:bits, 0:size(padding_bits)>>
    }
  }
}

fn compress_string(
  w: String,
  str: List(UtfCodepoint),
  dict: Dict(String, #(Int, Bool)),
  final_str: BitArray,
) -> BitArray {
  case str {
    [] -> {
      let size = find_bits(dict.size(dict) + 2)
      let #(_dict, output) = w_output(w, dict, False)
      <<final_str:bits, output:bits, reverse(<<2:size(size)>>):bits>>
    }
    [c, ..rest] -> {
      let char_just_added = !dict.has_key(dict, string.from_utf_codepoints([c]))
      let dict = case char_just_added {
        True -> {
          dict.insert(dict, string.from_utf_codepoints([c]), #(
            dict.size(dict) + 3,
            True,
          ))
        }
        False -> {
          dict
        }
      }

      let wc = w <> string.from_utf_codepoints([c])
      case dict.has_key(dict, wc) {
        True -> {
          compress_string(wc, rest, dict, final_str)
        }
        False -> {
          let #(dict, output) = w_output(w, dict, char_just_added)
          let dict = dict.insert(dict, wc, #(dict.size(dict) + 3, False))

          compress_string(string.from_utf_codepoints([c]), rest, dict, <<
            final_str:bits,
            output:bits,
          >>)
        }
      }
    }
  }
}

fn w_output(w: String, dict: Dict(String, #(Int, Bool)), char_just_added: Bool) {
  // This should never be reached if w isn't already in the dict
  let assert Ok(var) = dict.get(dict, w)

  case var {
    #(index, True) -> {
      let dict = dict.insert(dict, w, #(index, False))
      let marker_size = find_bits(index)
      let assert <<char_codepoint:utf8_codepoint, _rest:bits>> = <<w:utf8>>
      let char_val = string.utf_codepoint_to_int(char_codepoint)
      let #(size_marker, char_size) = {
        case find_bits(char_val) {
          index if index <= 8 -> #(0, 8)
          _ -> #(1, 16)
        }
      }
      let size_marker_bits = reverse(<<size_marker:size(marker_size)>>)
      let char_bits = reverse(<<char_val:size(char_size)>>)
      #(dict, <<size_marker_bits:bits, char_bits:bits>>)
    }
    #(index, False) -> {
      let map_size = dict.size(dict) + 2

      let map_size = case char_just_added {
        True -> map_size - 1
        False -> map_size
      }
      let size = find_bits(map_size)
      #(dict, reverse(<<index:size(size)>>))
    }
  }
}

pub fn decompress(bstring) {
  let assert Char(char) = decode_next_segment(bstring, dict.new())

  decompress_string(char.0, char.1, char.2, <<>>)
  |> to_utf16("")
}

fn decompress_string(
  w: BitArray,
  str: BitArray,
  dict: Dict(Int, BitArray),
  final_str: BitArray,
) -> BitArray {
  case decode_next_segment(str, dict) {
    Char(char) -> {
      let dict =
        dict.insert(char.2, dict.size(char.2) + 3, bit_array.append(w, char.0))
      decompress_string(char.0, char.1, dict, <<final_str:bits, w:bits>>)
    }
    Index(seq) -> {
      let c = case dict.get(dict, seq.0) {
        Ok(value) -> value
        Error(Nil) -> {
          case { dict.size(dict) + 3 } == seq.0 {
            True -> bit_array.append(w, <<w:bits-size(16)>>)
            False -> panic as "Error in decompressing"
          }
        }
      }
      let dict =
        dict.insert(
          dict,
          dict.size(dict) + 3,
          bit_array.append(w, <<c:bits-size(16)>>),
        )
      decompress_string(c, seq.1, dict, <<final_str:bits, w:bits>>)
    }
    EOF -> {
      <<final_str:bits, w:bits>>
    }
  }
}

fn decode_next_segment(bitstring, dict) -> DecodeType {
  let size = { dict.size(dict) + 3 } |> find_bits
  let assert <<dict_entry:size(size), rest:bits>> = bitstring
  let assert <<dict_entry:size(size)>> = reverse(<<dict_entry:size(size)>>)

  case dict_entry {
    0 -> {
      let assert <<c:size(8), rest:bits>> = rest
      let assert <<c:size(8)>> = reverse(<<c:size(8)>>)
      let assert Ok(codepoint) = string.utf_codepoint(c)
      let char = <<codepoint:utf16_codepoint>>
      let dict = dict.insert(dict, dict.size(dict) + 3, char)
      Char(#(char, rest, dict))
    }
    1 -> {
      let assert <<c:size(16), rest:bits>> = rest
      let assert <<c:size(16)>> = reverse(<<c:size(16)>>)
      let char = <<c:size(16)>>
      let dict = dict.insert(dict, dict.size(dict) + 3, char)
      Char(#(char, rest, dict))
    }
    2 -> {
      EOF
    }
    index -> {
      Index(#(index, rest))
    }
  }
}

// HELPERS

fn to_utf16(bitstring: BitArray, string: String) -> String {
  case bitstring {
    <<>> -> string
    _ -> {
      let assert <<c:size(16), rest:bits>> = bitstring
      //temporary fix as 65534 & 65535 aren't recognized as codepoints
      let assert Ok(str) = case c {
        65_534 -> {
          bit_array.to_string(<<239, 191, 190>>)
        }
        65_535 -> {
          bit_array.to_string(<<239, 191, 191>>)
        }
        other -> {
          let assert Ok(codepoint) = string.utf_codepoint(other)
          Ok(string.from_utf_codepoints([codepoint]))
        }
      }
      to_utf16(rest, string <> str)
    }
  }
}

fn find_bits(num: Int) {
  num
  |> int.to_base2
  |> string.length
}

fn reverse(bitstring: BitArray) {
  case bitstring {
    <<>> -> {
      <<>>
    }
    _ -> {
      let assert <<value:1-bits, rest:bits>> = bitstring
      bit_array.append(reverse(rest), value)
    }
  }
}

fn bit_size(bits: BitArray, size: Int) {
  case bits {
    <<_:bits-size(1), rest:bits>> -> bit_size(rest, size + 1)
    _ -> size
  }
}
