ParseJson(text) {
    parser := JsonParser(text)
    value := parser.ParseValue()
    parser.SkipWhitespace()
    if (parser.Position() < StrLen(text))
        throw Error("Unexpected trailing JSON data")
    return value
}

StringifyJson(value, indent := "    ", level := 0) {
    if (value is Map) {
        if (value.Count = 0)
            return "{}"

        lines := Array()
        for key, child in value {
            padding := StrRepeat(indent, level + 1)
            lines.Push(padding . QuoteJson(key) . ": " . StringifyJson(child, indent, level + 1))
        }
        return "{`n" . Join(lines, ",`n") . "`n" . StrRepeat(indent, level) . "}"
    }

    if (value is Array) {
        if (value.Length = 0)
            return "[]"

        lines := Array()
        for index, child in value {
            padding := StrRepeat(indent, level + 1)
            lines.Push(padding . StringifyJson(child, indent, level + 1))
        }
        return "[`n" . Join(lines, ",`n") . "`n" . StrRepeat(indent, level) . "]"
    }

    if (value is String) {
        return QuoteJson(value)
    }

    if (value = true)
        return "true"
    if (value = false)
        return "false"
    if (value = "")
        return '""'

    return value
}

QuoteJson(value) {
    escaped := StrReplace(value, "\", "\\")
    escaped := StrReplace(escaped, '"', '\"')
    escaped := StrReplace(escaped, "`n", "\n")
    escaped := StrReplace(escaped, "`r", "\r")
    escaped := StrReplace(escaped, "`t", "\t")
    return '"' . escaped . '"'
}

Join(items, separator) {
    result := ""
    for index, item in items {
        if (index > 1)
            result .= separator
        result .= item
    }
    return result
}

StrRepeat(text, count) {
    result := ""
    loop count {
        result .= text
    }
    return result
}

class JsonParser {
    __New(text) {
        this.Text := text
        this.PositionValue := 1
    }

    Position() {
        return this.PositionValue
    }

    SkipWhitespace() {
        while (this.PositionValue <= StrLen(this.Text)) {
            ch := SubStr(this.Text, this.PositionValue, 1)
            if (ch = " " || ch = "`n" || ch = "`r" || ch = "`t")
                this.PositionValue += 1
            else
                break
        }
    }

    ParseValue() {
        this.SkipWhitespace()
        if (this.PositionValue > StrLen(this.Text))
            throw Error("Unexpected end of JSON")

        ch := SubStr(this.Text, this.PositionValue, 1)
        if (ch = "{")
            return this.ParseObject()
        if (ch = "[")
            return this.ParseArray()
        if (ch = '"')
            return this.ParseString()
        if (ch = "t")
            return this.ParseLiteral("true", true)
        if (ch = "f")
            return this.ParseLiteral("false", false)
        if (ch = "n")
            return this.ParseLiteral("null", "")
        return this.ParseNumber()
    }

    ParseObject() {
        this.PositionValue += 1
        map := Map()
        this.SkipWhitespace()

        if (this.PositionValue <= StrLen(this.Text) && SubStr(this.Text, this.PositionValue, 1) = "}") {
            this.PositionValue += 1
            return map
        }

        while (true) {
            key := this.ParseString()
            this.SkipWhitespace()
            if (this.PositionValue > StrLen(this.Text) || SubStr(this.Text, this.PositionValue, 1) != ":")
                throw Error("Expected ':'")
            this.PositionValue += 1
            value := this.ParseValue()
            map[key] := value
            this.SkipWhitespace()

            if (this.PositionValue > StrLen(this.Text))
                throw Error("Unexpected end of JSON object")

            ch := SubStr(this.Text, this.PositionValue, 1)
            if (ch = "}") {
                this.PositionValue += 1
                break
            }
            if (ch != ",")
                throw Error("Expected ',' or '}'")
            this.PositionValue += 1
        }

        return map
    }

    ParseArray() {
        this.PositionValue += 1
        array := Array()
        this.SkipWhitespace()

        if (this.PositionValue <= StrLen(this.Text) && SubStr(this.Text, this.PositionValue, 1) = "]") {
            this.PositionValue += 1
            return array
        }

        while (true) {
            array.Push(this.ParseValue())
            this.SkipWhitespace()

            if (this.PositionValue > StrLen(this.Text))
                throw Error("Unexpected end of JSON array")

            ch := SubStr(this.Text, this.PositionValue, 1)
            if (ch = "]") {
                this.PositionValue += 1
                break
            }
            if (ch != ",")
                throw Error("Expected ',' or ']'")
            this.PositionValue += 1
        }

        return array
    }

    ParseString() {
        if (this.PositionValue > StrLen(this.Text) || SubStr(this.Text, this.PositionValue, 1) != '"')
            throw Error("Expected string")
        this.PositionValue += 1

        value := ""
        while (this.PositionValue <= StrLen(this.Text)) {
            ch := SubStr(this.Text, this.PositionValue, 1)
            if (ch = '"') {
                this.PositionValue += 1
                return value
            }
            if (ch = "\") {
                this.PositionValue += 1
                if (this.PositionValue > StrLen(this.Text))
                    throw Error("Invalid escape sequence")

                esc := SubStr(this.Text, this.PositionValue, 1)
                switch esc {
                    case '"': value .= '"'
                    case "\": value .= "\"
                    case "/": value .= "/"
                    case "b": value .= "`b"
                    case "f": value .= "`f"
                    case "n": value .= "`n"
                    case "r": value .= "`r"
                    case "t": value .= "`t"
                    case "u":
                        if (this.PositionValue + 4 > StrLen(this.Text))
                            throw Error("Invalid unicode escape")
                        hex := SubStr(this.Text, this.PositionValue + 1, 4)
                        value .= Chr(FormatInteger(hex))
                        this.PositionValue += 4
                    default: throw Error("Unsupported escape sequence")
                }
            } else {
                value .= ch
            }
            this.PositionValue += 1
        }

        throw Error("Unterminated string")
    }

    ParseLiteral(literal, value) {
        if (SubStr(this.Text, this.PositionValue, StrLen(literal)) != literal)
            throw Error("Invalid literal")
        this.PositionValue += StrLen(literal)
        return value
    }

    ParseNumber() {
        start := this.PositionValue
        while (this.PositionValue <= StrLen(this.Text)) {
            ch := SubStr(this.Text, this.PositionValue, 1)
            if (ch = "-" || ch = "+" || ch = "." || ch = "e" || ch = "E" || (ch >= "0" && ch <= "9"))
                this.PositionValue += 1
            else
                break
        }

        textValue := SubStr(this.Text, start, this.PositionValue - start)
        if (textValue = "")
            throw Error("Invalid number")
        return Number(textValue)
    }
}

FormatInteger(hex) {
    return Integer("0x" . hex)
}

LoadJsonFile(path, defaultValue := "") {
    if (!FileExist(path))
        return defaultValue

    try {
        return ParseJson(FileRead(path, "UTF-8"))
    } catch {
        return defaultValue
    }
}

SaveJsonFile(path, value) {
    fileObj := FileOpen(path, "w", "UTF-8")
    fileObj.Write(StringifyJson(value))
    fileObj.Close()
}
