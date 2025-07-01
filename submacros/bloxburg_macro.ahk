; ========== Initialization ==========
#MaxThreads 255
#Requires AutoHotkey v2.0
#SingleInstance Force
if A_ScreenDPI != 96
    throw Error("This macro requires a display scale of 100%"), ExitApp()
if (A_ScreenHeight<1080)
    throw Error("Seems like your screen height is small`nThe script won't work with a screen height under 1080`n`nExiting script, sorry.", "WARNING!!!", 0x10), ExitApp()
if (A_ScreenWidth<1920)
    throw Error("Seems like your screen width is small`nThe script won't work with a screen width under 1920`n`nExiting script, sorry.", "WARNING!!!", 0x10), ExitApp()
; ========== Libraries ==========
#Include "%A_ScriptDir%\..\lib"
#Include "Gdip_All.ahk"
#Include "Gdip_ImageSearch.ahk"
#Include "Roblox.ahk"
#Include "DarkMode.ahk"
#Warn VarUnset, Off
;OnError (e, mode) => (mode = "Return") ? -1 : 0
SetWorkingDir A_ScriptDir "\.."
CoordMode "Mouse", "Screen"
CoordMode "Pixel", "Screen"
SendMode "Event"
; ========== GDI+ Initialization ==========
if !(pToken := Gdip_Startup())
    throw Error("GDI+ failed to start, exiting script."), ExitApp()
; ========== Imports ==========
createFolder(folder) {
    if !FileExist(folder) {
        try
            DirCreate folder
        catch
            throw Error("Could not create the " folder " directory`nMeaning the macro won't work correctly`nTry moving the macor to a different folder", "WARNING!!!", 0x10), ExitApp()
    }
}
(conf := Map()).CaseSense := 0
createFolder("settings")
importConfig() { ; credits to the Natro Macro team for the structure/code
    global conf
    local config := Map()

    config["Settings"] := Map("WarningLabel", 0
        , "timeLimMins", 30
        , "StartKeybind", "F1"
        , "PauseKeybind", "F2"
        , "StopKeybind", "F3"
        , "AutoCloseRoblox", 1
        , "ClickDelay", 250
        , "FinishOrderDelay", 2000
        , "ImageSearchDelay", 100
        )
    config["Advanced"] := Map("ToppingDelay1", 100
        , "ToppingDelay2", 250
        , "OrderTimeout", 30
        , "Lettuce", 20
        , "Tomato", 50
        , "Beef", 10
        , "Veggie", 10
        , "Cheese", 10
        , "Onion", 40
        , "Fries", 20
        , "Sticks", 15
        , "Rings", 15
        , "Drink", 15
        , "Juice", 15
        , "Shake", 15
        , "OffsetX", 20
        , "OffsetY", 8
        )
    config["Status"] := Map("DiscordEnabled", 0
        , "DiscordMode", "Webhook"
        , "LastStartTime", "Never"
        , "ErrorCount", 0
        , "CurrentStatus", ""
        , "TotalRuntime", 0
        , "TotalOrders", 0
        , "Webhook", ""
        , "BotToken", ""
        , "ChannelID", ""
        , "CommandPrefix", "!"
        , "UserID", ""
        )
    config["Gui"] := Map("GuiX", 100
        , "GuiY", 100
        , "AlwaysOnTop", 0
        , "DebugConsole", 0 ; future implementation
        , "DarkMode", 0
        )
    for i, x in config
        for k, v in x
            conf[k] := v
    local iniPath := A_WorkingDir "\settings\config.ini"
    if FileExist(iniPath)
        readIni(iniPath)
    local ini := ""
    for i, x in config
    {
        ini .= "[" i "]`r`n"
        for k in x
            ini .= k "=" conf[k] "`r`n"
        ini .= "`r`n"
    }
    FileOpen(iniPath, "w-d").Write(ini)
}
importConfig()
readIni(path) {
    global conf
    local ini, str, c, p, k, v
    ini := FileOpen(path, "r"), str := ini.Read(), ini.Close()
    Loop Parse str, "`n", "`r" A_Space A_Tab {
        switch (c := SubStr(A_LoopField, 1, 1)) {
            case "[",";":
                continue
            default:
                if (p := InStr(A_LoopField, "="))
                    k := SubStr(A_LoopField, 1, p - 1), v := SubStr(A_LoopField, p + 1), conf[k] := IsInteger(v) ? Integer(v) : v
        }
    }
}
; ========== Warning Label ==========
if (conf["WarningLabel"]=0) {
	responce := MsgBox("
	(
	This macro has the ability to automate actions in Bloxburg, which are against the rules and CAN result in a ban if used irresponsibly.
Use this macro at your own risk.

I am NOT responsible for any bans that you get from using this macro.

You have been warned at
    1. In-Game (first time joining)
    2. On the github page README section
    3. This message itself

If you want to proceed. Agree to this message to continue with knowing the consequences.
	)", "WARNING!!!", "YesNo Icon! 4096")
    if (responce != "Yes")
        ExitApp
    updateValue("WarningLabel", 1, "Settings")
}
; ========== Roblox Client Setup ==========
WindowX:=WindowY:=WindowWidth:=WindowHeight:=0
GetRobloxClientPos()
; ========== Bitmaps ==========
(bitmaps := Map()).CaseSense := 0
#Include "%A_ScriptDir%\..\images\bitmaps.ahk"
; ========== GUI =========
version := "0.2.0"
OnExit(ExitFunc)
MainGui := Gui((conf["AlwaysOnTop"] ? "+AlwaysOnTop " : "") "+Border +OwnDialogs", "Bloxburg Macro")
MainGui.Show("x" conf["GuiX"] " y" conf["GuiY"] " w400 h200")
MainGui.OnEvent("Close", (*) => ExitApp())
MainGui.SetFont("s8 cDefault Norm", "Tahoma")
MainGui.SetFont("w700")
MainGui.Add("Text", "x7 y161 w90 -Wrap +BackgroundTrans", "Current Status:")
MainGui.Add("Text", "x95 y160 w200 -Wrap +BackgroundTrans +Border vStatus", " Loading... ")
(GuiCtrl := MainGui.Add("Text", "x400 y185 w90 -Wrap +BackgroundTrans", "v" version)), GuiCtrl.Move(394 - (TextWidth := TextExtend("v" version, GuiCtrl)))
MainGui.Add("Button", "x5 y177 w65 h20 -Wrap Disabled vStartButton", "Start (" conf["StartKeybind"] ")").OnEvent("Click", startUI)
MainGui.Add("Button", "x75 y177 w65 h20 -Wrap Disabled vPauseButton", "Pause (" conf["PauseKeybind"] ")").OnEvent("Click", pauseUI)
MainGui.Add("Button", "x145 y177 w65 h20 -Wrap Disabled vStopButton", "Stop (" conf["StopKeybind"] ")").OnEvent("Click", stopUI)

TabArr := ["Main", "Status", "Settings", "GUI", "Advanced"]
(TabCtrl := MainGui.Add("Tab", "x0 y-1 w400 h240 -Wrap " (conf["DarkMode"] ? "cFFFFFF" : "c000000"), TabArr)).OnEvent("Change", (*) => TabCtrl.Focus())
SendMessage 0x1331, 0, 20, , TabCtrl
; ========== Main Tab ==========
TabCtrl.UseTab("Main")
MainGui.SetFont("w700 Underline")
MainGui.Add("Text", "x125 y75 w126 +BackgroundTrans Center", "MORE JOB CHOICES COMING SOON!!!")
; ========== Status Tab ==========
TabCtrl.UseTab("Status")
MainGui.SetFont("w700 Underline")
MainGui.Add("Text", "x190 y70 w200 +BackgroundTrans", "DISCORD LOGS COMING SOON, feel free to config for now :3")
MainGui.Add("Text", "x4 y24 w126 +BackgroundTrans", "Discord Settings:")
MainGui.Add("Text", "x5 y105 w126 +BackgroundTrans", "Stats:")
MainGui.SetFont("s8 cDefault Norm", "Tahoma")
MainGui.Add("Text", "x110 y25 w126 +BackgroundTrans", "Enable Discord:")
(GuiCtrl := MainGui.Add("CheckBox", "x190 y25 w15 h15 vDiscordEnabled Checked" conf["DiscordEnabled"], "")).Section:="Status", GuiCtrl.OnEvent("Click", saveConfig)
MainGui.Add("Text", "x210 y25 w126 +BackgroundTrans", "Discord Mode:")
MainGui.Add("Button", "x277 y25 w12 h16 +Center vDiscordModeLeft", "<").OnEvent("Click", switchDiscordMode)
MainGui.Add("Button", "x342 y25 w12 h16 +Center vDiscordModeRight", ">").OnEvent("Click", switchDiscordMode)
MainGui.Add("Text", "x290 y26 w50 +BackgroundTrans +Center vDiscordMode", conf["DiscordMode"])
MainGui.Add("Text", "x5 y48 w90 +BackgroundTrans vUserIDLabel", "User ID:")
(GuiCtrl := MainGui.Add("Edit", "x65 y48 w120 h20 vUserID", conf["UserID"])).Section := "Status", GuiCtrl.OnEvent("Change", saveConfig)
MainGui.Add("Text", "x5 y78 w90 +BackgroundTrans vChannelIDLabel", "Channel ID:")
(GuiCtrl := MainGui.Add("Edit", "x65 y78 w120 h20 -Multi vChannelID", conf["ChannelID"])).Section := "Status", GuiCtrl.OnEvent("Change", saveConfig)
MainGui.Add("Text", "x5 y78 w90 +BackgroundTrans vWebhookLabel", "Webhook:")
(GuiCtrl := MainGui.Add("Edit", "x65 y78 w120 h20 -Multi vWebhook", conf["Webhook"])).Section := "Status", GuiCtrl.OnEvent("Change", saveConfig)
MainGui.Add("Text", "x190 y48 w90 +BackgroundTrans vBotTokenLabel", "Bot Token:")
(GuiCtrl := MainGui.Add("Edit", "x250 y48 w120 h20 -Multi vBotToken", conf["BotToken"])).Section := "Status", GuiCtrl.OnEvent("Change", saveConfig)
updateDiscordFields()
MainGui.Add("Text", "x15 y120 w100 +BackgroundTrans", "Failed Orders:")
MainGui.Add("Text", "x115 y120 w100 +BackgroundTrans vErrorCount", conf["ErrorCount"])
MainGui.Add("Text", "x15 y140 w100 +BackgroundTrans", "Successful Orders:")
MainGui.Add("Text", "x115 y140 w100 +BackgroundTrans vTotalOrders", conf["TotalOrders"])
MainGui.Add("Text", "x200 y120 w100 +BackgroundTrans", "Total Runtime:")
MainGui.Add("Text", "x300 y120 w100 +BackgroundTrans vTotalRuntime", conf["TotalRuntime"])
MainGui.Add("Text", "x200 y140 w100 +BackgroundTrans", "Last Start:")
MainGui.Add("Text", "x260 y140 w120 +BackgroundTrans vLastStartTime", conf["LastStartTime"])
MainGui.Add("Text", "x0 y100 w400 h1 0x7")
MainGui.Add("Text", "x0 y40 w105 h1 0x7")
MainGui.Add("Text", "x105 y20 w1 h20 0x7")
; ========== Settings Tab ==========
TabCtrl.UseTab("Settings")
MainGui.SetFont("w700 Underline")
MainGui.SetFont("s8 cDefault Norm", "Tahoma")
MainGui.Add("Text", "x10 y25 w110 +BackgroundTrans", "Start Keybind:")
(GuiCtrl := MainGui.Add("Edit", "x110 y23 w60 vStartKeybind", conf["StartKeybind"])).Section := "Settings", GuiCtrl.OnEvent("Change", saveConfig)
MainGui.Add("Text", "x10 y50 w110 +BackgroundTrans", "Pause Keybind:")
(GuiCtrl := MainGui.Add("Edit", "x110 y48 w60 vPauseKeybind", conf["PauseKeybind"])).Section := "Settings", GuiCtrl.OnEvent("Change", saveConfig)
MainGui.Add("Text", "x10 y75 w110 +BackgroundTrans", "Stop Keybind:")
(GuiCtrl := MainGui.Add("Edit", "x110 y73 w60 vStopKeybind", conf["StopKeybind"])).Section := "Settings", GuiCtrl.OnEvent("Change", saveConfig)
MainGui.Add("Text", "x10 y100 w110 +BackgroundTrans", "Time Limit (min):")
(GuiCtrl := MainGui.Add("Edit", "x110 y98 w60 Number vtimeLimMins", conf["timeLimMins"])).Section := "Settings", GuiCtrl.OnEvent("Change", saveConfig)
MainGui.Add("Text", "x30 y125 +BackgroundTrans", "Auto Close Roblox")
(GuiCtrl := MainGui.Add("CheckBox", "x10 y125 w15 h15 vAutoCloseRoblox Checked" conf["AutoCloseRoblox"], "")).Section:="Status", GuiCtrl.OnEvent("Click", saveConfig)
MainGui.Add("Text", "x200 y25 w110 +BackgroundTrans", "Click Delay (ms):")
(GuiCtrl := MainGui.Add("Edit", "x300 y23 w60 Number vClickDelay", conf["ClickDelay"])).Section := "Settings", GuiCtrl.OnEvent("Change", saveConfig)
MainGui.Add("Text", "x200 y50 w110 +BackgroundTrans", "Finish Order Delay:")
(GuiCtrl := MainGui.Add("Edit", "x300 y48 w60 Number vFinishOrderDelay", conf["FinishOrderDelay"])).Section := "Settings", GuiCtrl.OnEvent("Change", saveConfig)
MainGui.Add("Text", "x200 y75 w110 +BackgroundTrans", "Image Search Delay:")
(GuiCtrl := MainGui.Add("Edit", "x300 y73 w60 Number vImageSearchDelay", conf["ImageSearchDelay"])).Section := "Settings", GuiCtrl.OnEvent("Change", saveConfig)
; ========== GUI Tab ==========
TabCtrl.UseTab("GUI")
MainGui.SetFont("w700 Underline")
MainGui.Add("Text", "x25 y25 +BackgroundTrans", "Enable Dark Mode")
MainGui.Add("Text", "x170 y25 +BackgroundTrans", "Always On Top")
(GuiCtrl := MainGui.Add("CheckBox", "x5 y25 w15 h15 vDarkMode Checked" conf["DarkMode"], "Enable Dark Mode")).Section:="GUI", GuiCtrl.OnEvent("Click", applyDarkMode)
(GuiCtrl := MainGui.Add("CheckBox", "x150 y25 w15 h15 vAlwaysOnTop Checked" conf["AlwaysOnTop"], "Always on Top")).Section:="GUI", GuiCtrl.OnEvent("Click", alwaysOnTop)
; ========== Advanced Tab ==========
TabCtrl.UseTab("Advanced")
MainGui.SetFont("w700 Underline")
;MainGui.Add("Text", "x125 y75 w126 +BackgroundTrans Center", "MERGED TO MAIN TAB SOON!!!")
; This will be moved to Main gui when there's multiple jobs.
colX := [5, 136, 268]
rowY := 25
rowHeight := 21

fields := [
    "Beef", "Cheese", "Drink", "Fries", "Juice", "Lettuce",
    "Onion", "Rings", "Shake", "Sticks", "Tomato", "Veggie",
    "OffsetX", "OffsetY", "OrderTimeout", "ToppingDelay1", "ToppingDelay2"
]

MainGui.SetFont("s8 cDefault Norm", "Tahoma")

loop fields.Length {
    index := A_Index - 1
    col := Mod(index, 3)
    row := Floor(index / 3)

    name := fields[A_Index]
    x := colX[col+1]
    y := rowY + (row * rowHeight)

    MainGui.Add("Text", "x" x " y" y " w80 +BackgroundTrans", name ":")
    (GuiCtrl := MainGui.Add("Edit", "x" (x + 76) " y" y - 2 " w50 Number v" name, conf[name])).Section := "Advanced", GuiCtrl.OnEvent("Change", saveConfig)
}
; ========== Global Variables ==========
macroStatus := 1
macroStart := 0
; ========== Finished Loading ==========
setStatus("loaded!")
TabCtrl.Focus()
MainGui["StartButton"].Enabled := 1
MainGui["PauseButton"].Enabled := 1
MainGui["StopButton"].Enabled := 1
SetWindowTheme(MainGui, conf["DarkMode"])
SetWindowAttribute(MainGui, conf["DarkMode"])
; ========== GUI Functions ==========
switchDiscordMode(GuiCtrl, *) {
    global conf
    static val := ["Webhook", "Bot"], l := val.Length
    i := (conf["DiscordMode"] = "Bot" ? 2:1)
    MainGui["DiscordMode"].Text := conf["DiscordMode"] := val[(GuiCtrl.Name = "DiscordModeRight") ? (Mod(i, l) + 1): (Mod(l+i-2, l) +1)]
    IniWrite conf["DiscordMode"], "settings\config.ini", "Status", "DiscordMode"
    updateDiscordFields()
}
updateDiscordFields() {
    botEnabled := (conf["DiscordMode"] = "Bot") ? true:false, webhookEnabled := (conf["DiscordMode"] = "Webhook") ? true:false
    MainGui["BotTokenLabel"].Visible := botEnabled
    MainGui["BotToken"].Visible := botEnabled
    MainGui["ChannelIDLabel"].Visible := botEnabled
    MainGui["ChannelID"].Visible := botEnabled
    MainGui["WebhookLabel"].Visible := webhookEnabled
    MainGui["Webhook"].Visible := webhookEnabled
    MainGui["UserIDLabel"].Visible := true
    MainGui["UserID"].Visible := true
}
updateStats() {
    MainGui["ErrorCount"].Text := conf["ErrorCount"]
    MainGui["TotalOrders"].Text := conf["TotalOrders"]
    MainGui["TotalRuntime"].Text := conf["TotalRuntime"]
    MainGui["LastStartTime"].Text := conf["LastStartTime"]
}
saveConfig(GuiCtrl, *) {
    global conf
    switch GuiCtrl.Type, 0 {
        case "DDL":
            conf[GuiCtrl.Name] := GuiCtrl.Text
        default:
            conf[GuiCtrl.Name] := GuiCtrl.Value
    }
    IniWrite conf[GuiCtrl.Name], "settings\config.ini", GuiCtrl.Section, GuiCtrl.Name
}
alwaysOnTop(GuiCtrl, *){
	global
	saveConfig(GuiCtrl)
    MainGui.Opt((conf["AlwaysOnTop"] ? "+" : "-") "AlwaysOnTop")
}
applyDarkMode(GuiCtrl, *) {
    global
    saveConfig(GuiCtrl)
    SetWindowAttribute(MainGui, conf["DarkMode"])
    SetWindowTheme(MainGui, conf["DarkMode"])
    for ctrlName, ctrl in MainGui {
        try ctrl.SetFont("c" (conf["DarkMode"] ? "FFFFFF" : "000000"))
    }
}
; ========== General Function ==========
getIndexOf(valArr, search) {
    for i, v in valArr
        if (v = search)
            return i
    return 1  ; Default to 1 if not found
}
ClickAt(x, y) => (MouseMove(x+Random(-conf["OffsetX"],conf["OffsetX"])+windowX, y+Random(-conf["OffsetY"],conf["Offsety"])+windowY, 4),Click("Down"),Click("Up"),0)
ForceRoblox1080p() { ; this macro only works in 1080p since images are based on this resolution
    if !WinExist("Roblox ahk_exe RobloxPlayerBeta.exe")
        return
    bestMonitor:=0
    monitorCount := SysGet(80)
    monitorWidth := SysGet(0) ; main monitor
    monitorHeight := SysGet(1)
    virtualWidth := SysGet(78) ; inclused all the monitors "some math is involved to find out the res on that monitor"
    virtualHeight := SysGet(79)
    monitorLeft:=monitorTop:=0 ; main monitor
    if (monitorWidth=1920 && monitorHeight=1080)
        bestMonitor:=1
    else if (virtualWidth-monitorWidth>=0 && virtualHeight-monitorHeight>=0 && monitorCount=2)
        bestMonitor:=2
    if (bestMonitor=2)
        monitorLeft:=SysGet(76), monitorTop:=SysGet(77)
    minMaxRoblox(0)
    WinActivate()
    WinMove(monitorLeft, monitorTop,800,600,"Roblox ahk_exe RobloxPlayerBeta.exe") ; roblox loves to be weird, this is why this is here
    minMaxRoblox(1)
    WinMove(monitorLeft, monitorTop, 1920, 1080, "Roblox ahk_exe RobloxPlayerBeta.exe")
    minMaxRoblox(1)
}
minMaxRoblox(mode:=1) { ; 1=full screen, 0=windowed
    GetRobloxClientPos()
    try
        WinGetPos &posX, &posY, &posW, &posH, "ahk_id " GetRobloxHWND()
    catch TargetError
        posX:=posY:=posW:=posH:=0
    if (mode = 1 && posX!=windowX)
        send "{F11}"
    if (mode = 0 && posX=windowX)
        send "{F11}"
    sleep 200 ; animation stuff
}
nowUnix() => DateDiff(A_NowUTC, "19700101000000", "Seconds")
ExitFunc(*) {
    global conf, macroStart
    wp := Buffer(44)
    DllCall("GetWindowPlacement", "UInt", MainGui.Hwnd, "Ptr", wp)
    x := NumGet(wp, 28, "Int"), y := NumGet(wp, 32, "Int")
    if x>0
        try IniWrite x, "settings\config.ini", "Gui", "GuiX"
    if y>0
        try IniWrite y, "settings\config.ini", "Gui", "GuiY"
    try Gdip_Shutdown(pToken)
    if macroStart
        updateValue("TotalRuntime", nowUnix() - macroStart, "Status")
}
startUI(*) {
    SetTimer startMacro, -50
}
pauseUI(*) {
    return pauseMacro()
}
stopUI(*) {
    return stopMacro()
}
startMacro(*) {
    global macroStatus:=1, macroStart
    if !GetRobloxClientPos() {
        msgbox "No Roblox found."
        return 0
    }
    if (WindowWidth!=1920 || windowHeight!=1080)
        msgbox("Roblox will be automatically scaled to 1920x1080"), ForceRoblox1080p()
    updateValue("LastStartTime", FormatTime(A_Now, "yyyy/MM/dd hh:mm tt"), "Status"), updateStats()
    setStatus("Starting!")
    macroStart := nowUnix(), orderSuccess := ""
    while (conf["AutoCloseRoblox"] = 0 || nowUnix()-macroStart < Round(conf["timeLimMins"]*60))
        GetRobloxClientPos(),setStatus("order was a " ((successfulOrder:=orderBuilder())=1 ? "success":"fail")), (successfulOrder ? updateValue("TotalOrders",conf["TotalOrders"]+1, "Status"):updateValue("ErrorCount",conf["ErrorCount"]+1, "Status")), updateStats(), Sleep(100)
    updateValue("TotalRuntime", nowUnix() - macroStart, "Status")
    closeRoblox(), ExitApp()
}
pauseMacro(*) {
    global macroStatus
    if macroStatus
        macroStatus := 0, setStatus("Paused!")
    else
        macroStatus := 1, setStatus("Unpaused!")
    Pause -1
}
stopMacro(*) {
    try {
        Hotkey conf["StartKeybind"], "Off"
        Hotkey conf["PauseKeybind"], "Off"
        Hotkey conf["StopKeybind"], "Off"
    }
    Click "Up"
    setStatus("Stopping!")
    Reload
    Sleep 10000
}
TextExtend(text, textCtrl) {
    hDC := DllCall("GetDC", "Ptr", textCtrl.Hwnd, "Ptr")
	hFold := DllCall("SelectObject", "Ptr", hDC, "Ptr", SendMessage(0x31, , , textCtrl), "Ptr")
	nSize := Buffer(8)
	DllCall("GetTextExtentPoint32", "Ptr", hDC, "Str", text, "Int", StrLen(text), "Ptr", nSize)
	DllCall("SelectObject", "Ptr", hDC, "Ptr", hFold)
	DllCall("ReleaseDC", "Ptr", textCtrl.Hwnd, "Ptr", hDC)
	return NumGet(nSize, 0, "UInt")
}
setStatus(message) {
    try {
        MainGui["Status"].Text := message
    }
    try IniWrite message, "settings\config.ini", "Status", "CurrentStatus"
}
updateValue(var, val, section) {
    global conf
    try conf[var] := val
    try IniWrite val, "settings\config.ini", section, var
}
; ========== Order Functions ==========
genericItem(items, threshold) { ; detects both the side or drink, combined because smaller
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-140 "|" windowY+(windowHeight/2)-300 "|290|185")
    item := []
    for i in items
        if (Gdip_ImageSearch(pBMScreen, bitmaps[i],,,,,,threshold[A_Index]))
            item.Push(i)
    Gdip_DisposeImage(pBMScreen)
    if item.Length > 0 {
        while (size := itemSize()) = 0 || A_Index > 9
            Sleep conf["ImageSearchDelay"]
        item.Push(size)
    }
    return (item.Length > 0) ? item : 0
}
sideItem() => genericItem(["fries", "sticks", "rings"], [conf["Fries"],conf["Sticks"],conf["Rings"]])
drinkItem() => genericItem(["drink", "juice", "shake"], [conf["Drink"],conf["Juice"],conf["Shake"]])
itemSize() { ; 3=large, 2=medium, 1=small, 0=none
    pBMScreen := Gdip_BitmapFromScreen(windowX+968 "|" windowY+360 "|46|46")
    size := (Gdip_ImageSearch(pBMScreen, bitmaps["large"],,,,,,5) ? "large" : Gdip_ImageSearch(pBMScreen, bitmaps["medium"],,,,,,5) ? "medium" : (Gdip_ImageSearch(pBMScreen, bitmaps["small"],,,,,,5) ? "small" : 0))
    Gdip_DisposeImage(pBMScreen)
    return size
}
burgerItem() { ; returns array of each topping, 0 if nothing was detected
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-500 "|" windowY+(windowHeight/2)-300 "|900|185")
    items := [], threshold := [conf["Lettuce"],conf["Tomato"],conf["Beef"],conf["Veggie"],conf["Cheese"],conf["Onion"]]
    for item in ["lettuce", "tomato", "beef", "veggie", "cheese", "onion"]
        if (Gdip_ImageSearch(pBMScreen, bitmaps[item],&coords,,,,,threshold[A_Index]))
            items.Push([item, toppingAmount(coords)])
    Gdip_DisposeImage(pBMScreen)
    return (items.Length > 0) ? items : 0
}
toppingAmount(coords) { ; just used by burgerItems(), detects the amount of one topping in a burger
    x:=StrSplit(coords,",")[1]
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-500+x "|" windowY+370 "|100|100")
    amount := (Gdip_ImageSearch(pBMScreen, bitmaps["2"],,,,,,5) ? 2 : 1)
    Gdip_DisposeImage(pBMScreen)
    return amount
}
orderFinished(clear?) { ; 1=NPC finished ordering, 0=still ordering
    static ran:=0
    if IsSet(clear)
        return ran:=0
    ran++
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-200 "|" windowY+(windowHeight/2)-270 "|420|160")
    isEnd := 0
    if (Gdip_ImageSearch(pBMScreen, bitmaps["question"],,,,,,15)) || ran>=conf["OrderTimeout"]
        isEnd := 1, ran:=0, setStatus("Order is finished!")
    Gdip_DisposeImage(pBMScreen)
    return isEnd
}
orderBuilder() { ; returns if the order was a success or fail, 1=yes, 0=no, -1=error
    done:=Map("burger", 0, "side", 0, "drink", 0), built:=Map("burger", 0, "side", 0, "drink", 0)
    while (!orderFinished()) { ; NPC orders burger and side, drink is here and there
        for item in ["burger", "side", "drink"] {
            if done[item]
                continue
            sleep 300
            if (order := %item "Item"%()) {
                done[item]:=1
                if !built[item] {
                    %("build" StrTitle(item))%(order)
                    built[item]:=1
                    if (item = "drink" && built["drink"]=1) {
                        orderFinished(1)
                        break 2
                    }
                }
            }
        }
        sleep 200
    }
    ClickAt(1858, 710) ; confirm order
    sleep 750 ; to check if success or not
    pBMScreen := Gdip_BitmapFromScreen(windowX+1700 "|" windowY+480 "|100|100")
    success := ((Gdip_ImageSearch(pBMScreen, bitmaps["success"],,,,,,5)) ? 1 : (Gdip_ImageSearch(pBMScreen, bitmaps["fail"],,,,,,5)) ? 0 : 0)
    Gdip_DisposeImage(pBMScreen)
    sleep conf["FinishOrderDelay"]
    return success
}
buildBurger(order) { ; builds the whole burger.
    setStatus("Building Burger !")
    if !order
        return
    ClickAt(1858, 380) ; burger builder
    Sleep 500
    ClickAt(1665, 745) ; bottom bun
    for item in order {
        y:=Map("lettuce", 685, "tomato", 600, "beef", 540, "veggie", 540, "cheese", 475, "onion", 410), name:=item[1], amount:=item[2]
        Loop amount
            Sleep((A_Index = 1) ? conf["ToppingDelay1"] : conf["ToppingDelay2"]), ClickAt((name = "beef") ? 1616: (name = "veggie") ? 1700 : 1665, y[name])
    }
    ClickAt(1665, 350) ; top bun
}
buildGeneric(itemType, order) { ; builds both the side or drink, combined because smaller
    setStatus("Building " itemType "!")
    if !order
        return
    ClickAt(1858, (itemType = "side" ? 490:600)) ; 600 is drink
    sleep 500
    item := order[1], size := order[2]
    itemIcon := Map("fries|drink|small", 425, "sticks|juice|medium", 545, "rings|shake|large", 665)
    for group, y in itemIcon
        if InStr(group, item)
            ClickAt(1600, y)
    for group, y in itemIcon
        if InStr(group, size)
            ClickAt(1725, y)
}
buildSide(order) => buildGeneric("side", order)
buildDrink(order) => buildGeneric("drink", order)
; ========== Hotkeys ==========
try {
    Hotkey conf["StartKeybind"], startMacro, "On"
    Hotkey conf["PauseKeybind"], pauseMacro, "On"
    Hotkey conf["StopKeybind"], stopMacro, "On"
}
