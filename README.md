# GleamLZ_String
### This is a Gleam implementation of the [lz-string](https://github.com/pieroxy/lz-string) compression algorithm

### Installation
```sh
gleam add TODO:
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
  //"Hello World!
	
  //Base64
  gleamlz_string.compress_to_base64(string)
  //"BIUwNmD2AEDqkCcwBMCEQA=="
  gleamlz_string.decompress_from_base64("BIUwNmD2AEDqkCcwBMCEQA==")
  //"Hello World"
	
  //URI encoded
  gleamlz_string.compress_to_encoded_uri(string)
  //"BIUwNmD2AEDqkCcwBMCEQA$$"
  gleamlz_string.decompress_from_encoded_uri("BIUwNmD2AEDqkCcwBMCEQA$$")
  //"Hello World!"
    
}
```

### Note

TODO:

 - [ ] Add `compress_to_utf16`
 - [ ] Add tests for `base64` and `encoded_uri`
 - [ ] Add tests to automatically compare with the JavaScript version of LZ_String
 - [ ] Finish README
 - [ ] Add Documentation

### Docs
TODO

### Acknowledgements
[Original LZ_String by Pieroxy](https://github.com/pieroxy/lz-string)

Used [Michael Shapiro's elixir verson](https://github.com/koudelka/elixir-lz-string/tree/master) as reference 

### License
[Apache 2.0](./LICENSE)
