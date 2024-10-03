# GleamLZ_String

[![Package Version](https://img.shields.io/hexpm/v/gleamlz_string)](https://hex.pm/packages/gleamlz_string)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleamlz_string/)

### This is a Gleam implementation of the [lz-string](https://github.com/pieroxy/lz-string) compression algorithm

### Installation
```sh
gleam add gleamlz_string
```
### Usage
```gleam
import gleamlz_string
 
pub fn main() {
  let string = "Hello World!"

  //Uint8Array
  gleamlz_string.compress_to_uint8(string)
  //<<4, 133, 48, 54, 96, 246, 0, 64, 234, 144, 39, 48, 4, 192, 132, 64>>
  gleamlz_string.decompress_from_uint8(<<4, 133, 48, 54, 96, 246, 0, 64, 234, 144, 39, 48, 4, 192, 132, 64>>)
  //Ok("Hello World!)
	
  //Base64
  gleamlz_string.compress_to_base64(string)
  //"BIUwNmD2AEDqkCcwBMCEQA=="
  gleamlz_string.decompress_from_base64("BIUwNmD2AEDqkCcwBMCEQA==")
  //Ok("Hello World")
	
  //URI encoded
  gleamlz_string.compress_to_encoded_uri(string)
  //"BIUwNmD2AEDqkCcwBMCEQA$$"
  gleamlz_string.decompress_from_encoded_uri("BIUwNmD2AEDqkCcwBMCEQA$$")
  //Ok("Hello World!")
    
}
```

### Testing
Run `generate_testcases.sh` first which will generate a bunch of test data using the base JavaScript lib to compare with. 
Once that's done run `gleam test` 

### Docs
https://hexdocs.pm/gleamlz_string/

### Acknowledgements
[Original LZ_String by Pieroxy](https://github.com/pieroxy/lz-string)

Used [Michael Shapiro's elixir verson](https://github.com/koudelka/elixir-lz-string/tree/master) as reference 

### License
[Apache 2.0](./LICENSE)