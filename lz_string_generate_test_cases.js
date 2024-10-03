const LZString = require('lz-string');
const fs = require('node:fs');

function writeInt32LE(buffer, value, offset) {
    buffer.writeInt32LE(value, offset);
}

function generate_random_string(length){
    let string = ""
    for (let i = 0; i < length; i++ ){
        string += String.fromCodePoint(random_int_in_range())
    }
    return string
}

function random_int_in_range(){
    let j = Math.floor(Math.random() * 65_535)
    while (!(j < 55295 || j >= 57344)){
        j = Math.floor(Math.random() * 65_535)
    }
    return j
}

function compressed_sentence(str, type){
    if (type == "UINT8") {
        return LZString.compressToUint8Array(str)
    } else if (type == "Base64"){
        return LZString.compressToBase64(str)
    } else if (type == "URI"){
        return LZString.compressToEncodedURIComponent(str)
    }
}

function write_random_strings(amount, type, chars){
    for (let i = 0; i <= amount; i++){
        let str = generate_random_string(chars)
        write_test_case_to_file({
            input:  str,
            output: compressed_sentence(str, type)
        })
    }
}
function every_UTF8_char(){
    let codePoints = [];

    // Add code points from 0 to 55295
    for (let i = 0; i <= 55295; i++) {
        codePoints.push(i);
    }

    // Add code points from 57344 to 65535
    for (let i = 57344; i <= 65535; i++) {
        codePoints.push(i);
    }

    // Convert code points to a string
    return String.fromCodePoint(...codePoints);
}

const file = fs.openSync('output.bin', 'w');


function create_cases(){
    //2 known cases as a sanity test
    write_test_case_to_file({input: "hello, i am a 猫", output: compressed_sentence("hello, i am a 猫", "UINT8")})
    write_test_case_to_file({input: "今日は 今日は 今日は 今日は 今日は 今日は", output: compressed_sentence("今日は 今日は 今日は 今日は 今日は 今日は", "UINT8")})

    //Generate 1000 random strings and compress them
    write_random_strings(1000, "UINT8", 1000)
    write_random_strings(1000, "Base64", 1000)
    write_random_strings(1000, "URI", 1000)

    //Generatea  really long string and compress it
    write_random_strings(1, "UINT8", 1000000)
    write_random_strings(1, "Base64", 1000000)
    write_random_strings(1, "URI", 1000000)

    let allUTF8Characters = every_UTF8_char()
    write_test_case_to_file({input: "", output: compressed_sentence(allUTF8Characters, "UINT8")})
    write_test_case_to_file({input: "", output: compressed_sentence(allUTF8Characters, "Base64")})
    write_test_case_to_file({input: "", output: compressed_sentence(allUTF8Characters, "URI")})
}

// First 4 bytes are the size of the input string followed by the input string
// and the same for the output string
function write_test_case_to_file(testCase){
    const inputBuffer = Buffer.from(testCase.input, 'utf-8');
    const outputBuffer = Buffer.from(testCase.output);

    const buffer = Buffer.alloc(8 + inputBuffer.length + outputBuffer.length);
    writeInt32LE(buffer, inputBuffer.length, 0);
    inputBuffer.copy(buffer, 4);
    writeInt32LE(buffer, outputBuffer.length, 4 + inputBuffer.length);
    outputBuffer.copy(buffer, 8 + inputBuffer.length);
    fs.writeSync(file, buffer);
}

create_cases()
fs.closeSync(file);
