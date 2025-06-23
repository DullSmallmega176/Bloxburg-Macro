; ========== Setup ==========
timeLimit := 1800
/*
time limit is how long the script should run "IN SECONDS"
this is so you can set it and forget it, and it'll close after the time is up.Any
default - 1800 "30 minutes"
*/
; ========== Initialization ==========
#SingleInstance Force
#Warn VarUnset, Off
#Requires AutoHotkey v2.0
CoordMode "Mouse", "Screen"
CoordMode "Pixel", "Screen"
SendMode "Event"
if A_ScreenDPI != 96
    throw Error("This macro requires a display scale of 100%"), ExitApp()
if (A_ScreenHeight<1080)
    throw Error("Seems like your screen height is small`nThe script won't work with a screen height under 1080`n`nExiting script, sorry.", "WARNING!!!", 0x10), ExitApp()
if (A_ScreenWidth<1920)
    throw Error("Seems like your screen width is small`nThe script won't work with a screen width under 1920`n`nExiting script, sorry.", "WARNING!!!", 0x10), ExitApp()
; ========== Libraries ==========
#Include "%A_ScriptDir%\lib"
#Include "Gdip_All.ahk"
#Include "Gdip_ImageSearch.ahk"
#Include "Roblox.ahk"
; ========== GDI+ Initialization ==========
if !(pToken := Gdip_Startup())
    throw Error("GDI+ failed to start, exiting script."), ExitApp()
(bitmaps := Map()).CaseSense := 0
#Include "%A_ScriptDir%\images\bitmaps.ahk"
OnExit(*) => (Gdip_Shutdown(pToken), ExitApp(), -1)
; ========== Roblox Client Setup ==========
WindowX:=WindowY:=WindowWidth:=WindowHeight:=0
GetRobloxClientPos()
SC_L:="sc026" ; l
SC_Esc:="sc001" ; Esc
SC_Enter:="sc01c" ; Enter
; ========== Order Functions ==========
sideItem() { ; returns array of side and size, 0 if nothing was detected
    GetRobloxClientPos()
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-140 "|" windowY+(windowHeight/2)-300 "|290|185")
    item := []
    if (Gdip_ImageSearch(pBMScreen, bitmaps["fries"],,,,,,75))
        item.Push("fries")
    if (Gdip_ImageSearch(pBMScreen, bitmaps["sticks"],,,,,,75))
        item.Push("sticks")
    if (Gdip_ImageSearch(pBMScreen, bitmaps["rings"],,,,,,75))
        item.Push("rings")
    Gdip_DisposeImage(pBMScreen)
    if item.Length > 0 {
        while (size := itemSize()) = 0 || A_Index > 9
            Sleep(100)
        item.Push(size)
    }
    return (item.Length > 0) ? item : 0
}
drinkItem() { ; returns array of drink and size, 0 if nothing was detected
    GetRobloxClientPos()
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-140 "|" windowY+(windowHeight/2)-300 "|290|185")
    item := []
    if (Gdip_ImageSearch(pBMScreen, bitmaps["drink"],,,,,,50))
        item.Push("drink")
    if (Gdip_ImageSearch(pBMScreen, bitmaps["juice"],,,,,,50))
        item.Push("juice")
    if (Gdip_ImageSearch(pBMScreen, bitmaps["shake"],,,,,,50))
        item.Push("shake")
    Gdip_DisposeImage(pBMScreen)
    if item.Length > 0 {
        while (size := itemSize()) = 0 || A_Index > 9
            Sleep(100)
        item.Push(size)
    }
    return (item.Length > 0) ? item : 0
}
itemSize() { ; 3=large, 2=medium, 1=small, 0=none
    GetRobloxClientPos()
    pBMScreen := Gdip_BitmapFromScreen(windowX+968 "|" windowY+360 "|46|46")
    size := (Gdip_ImageSearch(pBMScreen, bitmaps["large"],,,,,,5) ? "large" : Gdip_ImageSearch(pBMScreen, bitmaps["medium"],,,,,,5) ? "medium" : (Gdip_ImageSearch(pBMScreen, bitmaps["small"],,,,,,5) ? "small" : 0))
    Gdip_DisposeImage(pBMScreen)
    return size
}
burgerItems() { ; returns array of each topping, 0 if nothing was detected
    GetRobloxClientPos()
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-500 "|" windowY+(windowHeight/2)-300 "|900|185")
    items := []
    if (Gdip_ImageSearch(pBMScreen, bitmaps["lettuce"],&coords,,,,,20))
        items.Push(["lettuce", toppingAmount(coords)])
    if (Gdip_ImageSearch(pBMScreen, bitmaps["tomato"],&coords,,,,,50))
        items.Push(["tomato", toppingAmount(coords)])
    if (Gdip_ImageSearch(pBMScreen, bitmaps["beef"],&coords,,,,,10))
        items.Push(["beef", toppingAmount(coords)])
    if (Gdip_ImageSearch(pBMScreen, bitmaps["veggie"],&coords,,,,,10))
        items.Push(["veggie", toppingAmount(coords)])
    if (Gdip_ImageSearch(pBMScreen, bitmaps["cheese"],&coords,,,,,10))
        items.Push(["cheese", toppingAmount(coords)])
    if (Gdip_ImageSearch(pBMScreen, bitmaps["onion"],&coords,,,,,50))
        items.Push(["onion", toppingAmount(coords)])
    Gdip_DisposeImage(pBMScreen)
    return (items.Length > 0) ? items : 0
}
toppingAmount(coords) { ; just used by burgerItems(), detects the amount of toppings in a burger
    GetRobloxClientPos()
    x:=StrSplit(coords,",")[1]
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-500+x "|" windowY+370 "|100|100")
    amount := (Gdip_ImageSearch(pBMScreen, bitmaps["1"],,,,,,20)) ? 1 : (Gdip_ImageSearch(pBMScreen, bitmaps["2"],,,,,,20) ? 2 : 1)
    Gdip_DisposeImage(pBMScreen)
    return amount
}
orderFinished() { ; 1=NPC finished ordering, 0=still ordering
    static ran:=0
    ran++
    GetRobloxClientPos()
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-200 "|" windowY+(windowHeight/2)-270 "|420|160")
    isEnd := 0
    if (Gdip_ImageSearch(pBMScreen, bitmaps["question"],,,,,,15)) || ran=30
        isEnd := 1, ran:=0
    Gdip_DisposeImage(pBMScreen)
    return isEnd
}
orderBuilder() { ; builds the order, returns a map of the whole order, 0 if nothing was detected
    burger:=side:=drink:=0
    burgerBuilt:=sideBuilt:=drinkBuilt:=0
    wholeOrder := Map()
    while (!orderFinished()) { ; NPC orders burger and side, drink is here and there
        if !burger {
            burgerOrder := burgerItems()
            if burgerOrder {
                burger := 1
                if !burgerBuilt
                    buildBurger(burgerOrder), burgerBuilt:=1
            }
        }
        if !side {
            sideOrder := sideItem()
            if sideOrder {
                side:=1
                if !sideBuilt
                    buildSide(sideOrder), sideBuilt:=1
            }
        }
        if !drink {
            drinkOrder := drinkItem()
            if drinkOrder {
                drink := 1
                if !drinkBuilt {
                    buildDrink(drinkOrder)
                    break
                }
            }
        }
        sleep(100)
    }
    ClickAt(1858, 710) ; confirm order
    sleep 3000 ; gives a delay until it starts again
}
buildBurger(order) {
    if !order
        return
    ClickAt(1858, 380) ; burger builder
    Sleep 500
    ClickAt(1665, 745) ; bottom bun
    for item in order {
        name := item[1], amount := item[2]
        Loop amount {
            Sleep (A_Index = 1) ? 100 : 250
            if name = "lettuce"
                ClickAt(1665, 685)
            else if name = "tomato"
                ClickAt(1665, 600)
            else if name = "beef"
                ClickAt(1616, 540)
            else if name = "veggie"
                ClickAt(1700, 540)
            else if name = "cheese"
                ClickAt(1665, 475)
            else if name = "onion"
                ClickAt(1665, 410)
        }
    }
    ClickAt(1665, 350) ; top bun
}
buildSide(order) {
    if !order
        return
    ClickAt(1858, 490)
    Sleep 500
    item := order[1], size := order[2]
    if item = "fries"
        ClickAt(1600, 425)
    else if item = "sticks"
        ClickAt(1600, 545)
    else if item = "rings"
        ClickAt(1600, 665)
    Sleep 100
    if size = "small"
        ClickAt(1725, 425)
    else if size = "medium"
        ClickAt(1725, 545)
    else if size = "large"
        ClickAt(1725, 665)
}
buildDrink(order) {
    if !order
        return
    ClickAt(1858, 600)
    Sleep 500
    item := order[1], size := order[2]
    if item = "drink"
        ClickAt(1600, 425)
    else if item = "juice"
        ClickAt(1600, 545)
    else if item = "shake"
        ClickAt(1600, 665)
    Sleep 100
    if size = "small"
        ClickAt(1725, 425)
    else if size = "medium"
        ClickAt(1725, 545)
    else if size = "large"
        ClickAt(1725, 665)
}
ClickAt(x, y) {
    GetRobloxClientPos()
    MouseMove(x+Random(-20,20)+windowX,y+Random(-8,10)+windowY, 4)
    Click "Down"
    Click "Up"
}
ForceRoblox1080p() {
    if !WinExist("Roblox ahk_exe RobloxPlayerBeta.exe")
        return

    bestMonitor:=0
    monitorCount := SysGet(80)

    monitorWidth := SysGet(0)
    monitorHeight := SysGet(1)

    virtualWidth := SysGet(78)
    virtualHeight := SysGet(79)

    monitorLeft:=monitorTop:=0

    if (monitorWidth=1920 && monitorHeight=1080) ; checks if main monitor is 1920x1080, if not. proceed
        bestMonitor:=1
    else if (virtualWidth-monitorWidth>=0 && virtualHeight-monitorHeight>=0 && monitorCount=2) ; checks if any other monitor is 1920x1080 "failsafe"
        bestMonitor:=2
    
    if (bestMonitor=2)
        monitorLeft:=SysGet(76), monitorTop:=SysGet(77)
    try
        WinGetPos &posX, &posY, &posW, &posH, "ahk_id " GetRobloxHWND()
    catch TargetError
        posX:=posY:=posW:=posH:=0
    if (posX!=windowX)
        send "{F11}"
    sleep 100
    WinActivate()
    WinMove(monitorLeft, monitorTop,800,600,"Roblox ahk_exe RobloxPlayerBeta.exe") ; roblox loves to be weird, this is why this is here
    WinMove(monitorLeft, monitorTop, 1920, 1080, "Roblox ahk_exe RobloxPlayerBeta.exe")
    sleep 100
    if (posX)
    sleep 100
}
nowUnix() => DateDiff(A_NowUTC, "19700101000000", "Seconds")
; ========== Hotkeys ==========
F1:: {
    GetRobloxClientPos()
    if !(WindowWidth=1920 && windowHeight=1080)
        msgbox("Roblox will be automatically scaled to 1920x1080"), ForceRoblox1080p()
    start := nowUnix()
    while (nowUnix()-start < timeLimit)
        orderBuilder(), Sleep(100)
    closeRoblox()
}
F2::Reload
F3::ExitApp
