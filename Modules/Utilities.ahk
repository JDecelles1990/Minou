#Requires AutoHotkey v2.0

; ==============================================================================
; Minou - Utilities Module (AutoHotkey v2)
; Provides native system tools, encoding/decoding, formatters, and diagnostics.
; ==============================================================================

DispatchInternalUtility(fnName) {
    switch fnName {
        case "GenerateGuid": GenerateGuid()
        case "GenerateUnixTimestamp": GenerateUnixTimestamp()
        case "UrlEncodeClipboard": UrlEncodeClipboard()
        case "UrlDecodeClipboard": UrlDecodeClipboard()
        case "Base64EncodeClipboard": Base64EncodeClipboard()
        case "Base64DecodeClipboard": Base64DecodeClipboard()
        case "GenerateSha256Clipboard": GenerateSha256Clipboard()
        case "BeautifyClipboardJson": BeautifyClipboardJson()
        case "MinifyClipboardJson": MinifyClipboardJson()
        case "EscapeClipboardString": EscapeClipboardString()
        case "CapitalizeSqlKeywords": CapitalizeSqlKeywords()
        case "OpenTerminalAtActiveExplorer": OpenTerminalAtActiveExplorer()
        case "GitStatusAtActiveExplorer": GitStatusAtActiveExplorer()
        case "InspectPathEnvironment": InspectPathEnvironment()
        case "ToggleExplorerHiddenAndExt": ToggleExplorerHiddenAndExt()
        case "FlushDns": FlushDns()
        case "PingGatewayAndDns": PingGatewayAndDns()
        case "GetIpSummary": GetIpSummary()
        case "ShowListeningPorts": ShowListeningPorts()
        case "InspectDevPorts": InspectDevPorts()
        case "RestartExplorer": RestartExplorer()
        case "PurgeTempFiles": PurgeTempFiles()
        default:
            ToolTip("Unknown utility: " . fnName)
            SetTimer((*) => ToolTip(), -1500)
    }
}

ShowUtilityFeedback(msg) {
    ToolTip(msg)
    SetTimer((*) => ToolTip(), -2000)
}

; ------------------------------------------------------------------------------
; 1. Encoders & Generators
; ------------------------------------------------------------------------------

GenerateGuid() {
    guidBuf := Buffer(16, 0)
    if (DllCall("ole32\CoCreateGuid", "ptr", guidBuf) = 0) {
        guidStr := Format("{:08x}-{:04x}-{:04x}-{:02x}{:02x}-{:02x}{:02x}{:02x}{:02x}{:02x}{:02x}",
            NumGet(guidBuf, 0, "UInt"),
            NumGet(guidBuf, 4, "UShort"),
            NumGet(guidBuf, 6, "UShort"),
            NumGet(guidBuf, 8, "UChar"),
            NumGet(guidBuf, 9, "UChar"),
            NumGet(guidBuf, 10, "UChar"),
            NumGet(guidBuf, 11, "UChar"),
            NumGet(guidBuf, 12, "UChar"),
            NumGet(guidBuf, 13, "UChar"),
            NumGet(guidBuf, 14, "UChar"),
            NumGet(guidBuf, 15, "UChar")
        )
        A_Clipboard := guidStr
        ShowUtilityFeedback("✓ Copied UUID v4: " . guidStr)
        return guidStr
    }
}

GenerateUnixTimestamp() {
    nowUtc := TimeAdd(A_NowUTC, 0, "Seconds")
    epochSec := DateDiff(nowUtc, "19700101000000", "Seconds")
    A_Clipboard := String(epochSec)
    ShowUtilityFeedback("✓ Copied Unix Timestamp: " . epochSec)
    return epochSec
}

UrlEncode(str) {
    if (str = "")
        return ""
    VarSetStrCapacity(&buf, StrPut(str, "UTF-8"))
    len := StrPut(str, StrPtr(buf), "UTF-8") - 1
    res := ""
    loop len {
        b := NumGet(StrPtr(buf), A_Index - 1, "UChar")
        ch := Chr(b)
        if (RegExMatch(ch, "[a-zA-Z0-9_\-\.~]")) {
            res .= ch
        } else {
            res .= Format("%{:02X}", b)
        }
    }
    return res
}

UrlDecode(str) {
    if (str = "")
        return ""
    temp := StrReplace(str, "+", " ")
    buf := Buffer(StrLen(temp) + 1, 0)
    outIdx := 0
    i := 1
    len := StrLen(temp)
    while (i <= len) {
        c := SubStr(temp, i, 1)
        if (c = "%" && i + 2 <= len) {
            hex := SubStr(temp, i + 1, 2)
            try {
                NumPut("UChar", Integer("0x" . hex), buf, outIdx)
                outIdx++
                i += 3
                continue
            }
        }
        NumPut("UChar", Ord(c), buf, outIdx)
        outIdx++
        i++
    }
    NumPut("UChar", 0, buf, outIdx)
    return StrGet(buf, "UTF-8")
}

UrlEncodeClipboard() {
    clip := A_Clipboard
    if (clip = "") {
        ShowUtilityFeedback("⚠ Clipboard is empty")
        return
    }
    encoded := UrlEncode(clip)
    A_Clipboard := encoded
    ShowUtilityFeedback("✓ URL Encoded clipboard contents")
}

UrlDecodeClipboard() {
    clip := A_Clipboard
    if (clip = "") {
        ShowUtilityFeedback("⚠ Clipboard is empty")
        return
    }
    decoded := UrlDecode(clip)
    A_Clipboard := decoded
    ShowUtilityFeedback("✓ URL Decoded clipboard contents")
}

Base64Encode(str) {
    if (str = "")
        return ""
    utf8Len := StrPut(str, "UTF-8") - 1
    utf8Buf := Buffer(utf8Len + 1, 0)
    StrPut(str, utf8Buf, "UTF-8")

    outLen := 0
    ; CRYPT_STRING_BASE64 (0x1) | CRYPT_STRING_NOCRLF (0x40000000) = 0x40000001
    DllCall("Crypt32.dll\CryptBinaryToStringW", "Ptr", utf8Buf, "UInt", utf8Len, "UInt", 0x40000001, "Ptr", 0, "UInt*", &outLen)
    if (outLen = 0)
        return ""
    b64Buf := Buffer(outLen * 2, 0)
    DllCall("Crypt32.dll\CryptBinaryToStringW", "Ptr", utf8Buf, "UInt", utf8Len, "UInt", 0x40000001, "Ptr", b64Buf, "UInt*", &outLen)
    return StrGet(b64Buf, "UTF-16")
}

Base64Decode(b64Str) {
    if (b64Str = "")
        return ""
    outLen := 0
    DllCall("Crypt32.dll\CryptStringToBinaryW", "Str", b64Str, "UInt", StrLen(b64Str), "UInt", 1, "Ptr", 0, "UInt*", &outLen, "Ptr", 0, "Ptr", 0)
    if (outLen = 0)
        return ""
    rawBuf := Buffer(outLen + 1, 0)
    DllCall("Crypt32.dll\CryptStringToBinaryW", "Str", b64Str, "UInt", StrLen(b64Str), "UInt", 1, "Ptr", rawBuf, "UInt*", &outLen, "Ptr", 0, "Ptr", 0)
    return StrGet(rawBuf, "UTF-8")
}

Base64EncodeClipboard() {
    clip := A_Clipboard
    if (clip = "") {
        ShowUtilityFeedback("⚠ Clipboard is empty")
        return
    }
    res := Base64Encode(clip)
    A_Clipboard := res
    ShowUtilityFeedback("✓ Base64 Encoded clipboard contents")
}

Base64DecodeClipboard() {
    clip := A_Clipboard
    if (clip = "") {
        ShowUtilityFeedback("⚠ Clipboard is empty")
        return
    }
    try {
        res := Base64Decode(clip)
        A_Clipboard := res
        ShowUtilityFeedback("✓ Base64 Decoded clipboard contents")
    } catch {
        ShowUtilityFeedback("⚠ Invalid Base64 string")
    }
}

GenerateSha256Clipboard() {
    clip := A_Clipboard
    if (clip = "") {
        ShowUtilityFeedback("⚠ Clipboard is empty")
        return
    }
    try {
        shell := ComObject("WScript.Shell")
        escaped := StrReplace(clip, '"', '\"')
        escaped := StrReplace(escaped, "`r`n", "")
        cmd := 'powershell.exe -NoProfile -Command "[System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes(\"' . escaped . '\"))).Replace(\"-\",\"\").ToLower()"'
        exec := shell.Exec(cmd)
        hashResult := Trim(exec.StdOut.ReadAll())
        if (hashResult != "") {
            A_Clipboard := hashResult
            ShowUtilityFeedback("✓ Copied SHA-256: " . SubStr(hashResult, 1, 14) . "...")
        }
    } catch Error as err {
        ShowUtilityFeedback("⚠ SHA-256 Error: " . err.Message)
    }
}

; ------------------------------------------------------------------------------
; 2. Code & Data Formatting
; ------------------------------------------------------------------------------

BeautifyClipboardJson() {
    clip := Trim(A_Clipboard)
    if (clip = "") {
        ShowUtilityFeedback("⚠ Clipboard is empty")
        return
    }
    try {
        parser := JsonParser(clip)
        val := parser.ParseValue()
        pretty := StringifyJson(val, 4)
        A_Clipboard := pretty
        ShowUtilityFeedback("✓ Prettified JSON (4-space indent) copied")
    } catch Error as err {
        ShowUtilityFeedback("⚠ Invalid JSON: " . err.Message)
    }
}

MinifyClipboardJson() {
    clip := Trim(A_Clipboard)
    if (clip = "") {
        ShowUtilityFeedback("⚠ Clipboard is empty")
        return
    }
    try {
        parser := JsonParser(clip)
        val := parser.ParseValue()
        mini := StringifyJson(val, 0)
        A_Clipboard := mini
        ShowUtilityFeedback("✓ Minified JSON copied")
    } catch Error as err {
        ShowUtilityFeedback("⚠ Invalid JSON: " . err.Message)
    }
}

EscapeClipboardString() {
    clip := A_Clipboard
    if (clip = "") {
        ShowUtilityFeedback("⚠ Clipboard is empty")
        return
    }
    escaped := StrReplace(clip, "\", "\\")
    escaped := StrReplace(escaped, "`"", "\`"")
    escaped := StrReplace(escaped, "`r`n", "\n")
    escaped := StrReplace(escaped, "`n", "\n")
    escaped := StrReplace(escaped, "`t", "\t")
    A_Clipboard := escaped
    ShowUtilityFeedback("✓ Escaped string copied")
}

CapitalizeSqlKeywords() {
    clip := A_Clipboard
    if (clip = "") {
        ShowUtilityFeedback("⚠ Clipboard is empty")
        return
    }
    keywords := ["select", "from", "where", "insert into", "values", "update", "set", "delete", "join", "left join", "right join", "inner join", "outer join", "cross join", "group by", "order by", "having", "limit", "offset", "union", "union all", "and", "or", "not", "is null", "is not null", "in", "like", "between", "as", "case", "when", "then", "else", "end", "distinct", "create table", "drop table", "alter table"]
    formatted := clip
    for kw in keywords {
        pattern := "i)\b" . StrReplace(kw, " ", "\s+") . "\b"
        formatted := RegExReplace(formatted, pattern, StrUpper(kw))
    }
    A_Clipboard := formatted
    ShowUtilityFeedback("✓ SQL keywords capitalized")
}

; ------------------------------------------------------------------------------
; 3. Git & Environment
; ------------------------------------------------------------------------------

GetActiveExplorerPath() {
    activeHwnd := WinActive("ahk_class CabinetWClass")
    if (!activeHwnd)
        activeHwnd := WinActive("ahk_class ExploreWClass")
    if (!activeHwnd)
        return ""
    try {
        shellApp := ComObject("Shell.Application")
        for window in shellApp.Windows {
            if (window.HWND = activeHwnd) {
                uri := window.Document.Folder.Self.Path
                if (InStr(uri, "::") = 0)
                    return uri
            }
        }
    }
    return ""
}

OpenTerminalAtActiveExplorer() {
    path := GetActiveExplorerPath()
    if (path != "" && DirExist(path)) {
        SafeRun("wt.exe", '-d "' . path . '"')
        ShowUtilityFeedback("✓ Terminal opened at: " . path)
    } else {
        SafeRun("wt.exe")
        ShowUtilityFeedback("✓ Terminal opened")
    }
}

GitStatusAtActiveExplorer() {
    path := GetActiveExplorerPath()
    if (path = "" || !DirExist(path)) {
        ShowUtilityFeedback("⚠ Active window is not an Explorer folder")
        return
    }
    if (!DirExist(path . "\.git") && !FileExist(path . "\.git")) {
        ShowUtilityFeedback("⚠ No .git repo found in current folder")
        return
    }
    try {
        shell := ComObject("WScript.Shell")
        exec := shell.Exec('git.exe -C "' . path . '" status -sb')
        output := Trim(exec.StdOut.ReadAll())
        if (output != "") {
            A_Clipboard := output
            MsgBox(output, "Git Status: " . path, "Iconi")
        } else {
            ShowUtilityFeedback("✓ Git working tree clean")
        }
    } catch Error as err {
        ShowUtilityFeedback("⚠ Git error: " . err.Message)
    }
}

InspectPathEnvironment() {
    sysPath := EnvGet("PATH")
    paths := StrSplit(sysPath, ";")
    report := "Active PATH Entries (" . paths.Length . " found):`n`n"
    for idx, p in paths {
        p := Trim(p)
        if (p = "")
            continue
        exists := DirExist(p) ? "✓ [OK]" : "✗ [NOT FOUND]"
        report .= idx . ". " . exists . " " . p . "`n"
    }
    A_Clipboard := report
    ShowUtilityFeedback("✓ %PATH% summary copied (" . paths.Length . " entries)")
    MsgBox(report, "Minou: Environment %PATH% Inspector", "Iconi")
}

ToggleExplorerHiddenAndExt() {
    try {
        regKey := "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        currentHidden := RegRead(regKey, "Hidden", 2)
        newHidden := (currentHidden == 1) ? 2 : 1
        RegWrite(newHidden, "REG_DWORD", regKey, "Hidden")

        currentExt := RegRead(regKey, "HideFileExt", 1)
        newExt := (currentExt == 1) ? 0 : 1
        RegWrite(newExt, "REG_DWORD", regKey, "HideFileExt")

        PostMessage(0x0111, 41504, 0, , "ahk_class CabinetWClass")
        PostMessage(0x0111, 41504, 0, , "ahk_class ExploreWClass")
        PostMessage(0x0111, 28931, 0, , "ahk_class Progman")

        stateStr := (newHidden == 1) ? "Shown" : "Hidden"
        ShowUtilityFeedback("✓ Hidden files & extensions: " . stateStr)
    } catch Error as err {
        ShowUtilityFeedback("⚠ Registry error: " . err.Message)
    }
}

; ------------------------------------------------------------------------------
; 4. Network & SysAdmin Diagnostics
; ------------------------------------------------------------------------------

FlushDns() {
    RunWait("ipconfig.exe /flushdns", , "Hide")
    ShowUtilityFeedback("✓ DNS Cache Flushed successfully")
}

PingGatewayAndDns() {
    try {
        shell := ComObject("WScript.Shell")
        exec := shell.Exec('powershell.exe -NoProfile -Command "Test-Connection 1.1.1.1, 8.8.8.8 -Count 1 | Select-Object Address, ResponseTime | Format-Table -HideTableHeaders"')
        out := Trim(exec.StdOut.ReadAll())
        if (out != "") {
            lines := StrSplit(out, "`n", "`r")
            summary := ""
            for line in lines {
                line := Trim(line)
                if (line != "")
                    summary .= (summary != "" ? " | " : "") . line . "ms"
            }
            A_Clipboard := summary
            ShowUtilityFeedback("✓ Ping: " . summary)
        } else {
            ShowUtilityFeedback("⚠ Ping failed or timed out")
        }
    } catch Error as err {
        ShowUtilityFeedback("⚠ Ping error: " . err.Message)
    }
}

GetIpSummary() {
    localIp := A_IPAddress1
    publicIp := "Unknown"
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", "https://api.ipify.org", true)
        http.Send()
        if (http.WaitForResponse(2)) {
            publicIp := Trim(http.ResponseText)
        }
    }
    summary := "Local IP: " . localIp . " | Public IP: " . publicIp
    A_Clipboard := summary
    ShowUtilityFeedback("✓ Copied: " . summary)
}

ShowListeningPorts() {
    try {
        shell := ComObject("WScript.Shell")
        exec := shell.Exec('cmd.exe /c netstat -ano -p tcp | findstr /i "LISTENING"')
        out := Trim(exec.StdOut.ReadAll())
        if (out != "") {
            A_Clipboard := out
            ShowUtilityFeedback("✓ Copied listening ports list to clipboard")
            MsgBox(SubStr(out, 1, 1500) . (StrLen(out) > 1500 ? "`n...[Truncated, full list in clipboard]" : ""), "Minou: Active Listening Ports", "Iconi")
        } else {
            ShowUtilityFeedback("No listening TCP ports found")
        }
    } catch Error as err {
        ShowUtilityFeedback("⚠ Error querying netstat: " . err.Message)
    }
}

InspectDevPorts() {
    try {
        shell := ComObject("WScript.Shell")
        exec := shell.Exec('cmd.exe /c netstat -ano | findstr ":3000 :5000 :8000 :8080 :5173"')
        out := Trim(exec.StdOut.ReadAll())
        if (out != "") {
            A_Clipboard := out
            ShowUtilityFeedback("✓ Found active dev ports! Copied to clipboard")
            MsgBox(out, "Minou: Common Dev Ports (3000, 5000, 8000, 8080, 5173)", "Iconi")
        } else {
            ShowUtilityFeedback("✓ All common dev ports (3000, 5000, 8080...) are FREE")
        }
    } catch Error as err {
        ShowUtilityFeedback("⚠ Error inspecting dev ports: " . err.Message)
    }
}

RestartExplorer() {
    RunWait("taskkill.exe /f /im explorer.exe", , "Hide")
    Sleep(300)
    Run("explorer.exe")
    ShowUtilityFeedback("✓ Windows Explorer restarted")
}

PurgeTempFiles() {
    tempDir := EnvGet("TEMP")
    deletedCount := 0
    if (tempDir != "" && DirExist(tempDir)) {
        loop files, tempDir . "\*.*", "DF" {
            try {
                if (InStr(FileExist(A_LoopFileFullPath), "D"))
                    DirDelete(A_LoopFileFullPath, 1)
                else
                    FileDelete(A_LoopFileFullPath)
                deletedCount++
            }
        }
    }
    ShowUtilityFeedback("✓ %TEMP% purged (" . deletedCount . " items cleaned)")
}