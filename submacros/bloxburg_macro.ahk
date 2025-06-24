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
#Include "%A_ScriptDir%\..\lib"
#Include "Gdip_All.ahk"
#Include "Gdip_ImageSearch.ahk"
#Include "Roblox.ahk"
; ========== GDI+ Initialization ==========
if !(pToken := Gdip_Startup())
    throw Error("GDI+ failed to start, exiting script."), ExitApp()
(bitmaps := Map()).CaseSense := 0
#Include "%A_ScriptDir%\..\images\bitmaps.ahk"
OnExit(*) => (Gdip_Shutdown(pToken), ExitApp(), -1)
; ========== Roblox Client Setup ==========
WindowX:=WindowY:=WindowWidth:=WindowHeight:=0
GetRobloxClientPos()
SC_L:="sc026" ; l
SC_Esc:="sc001" ; Esc
SC_Enter:="sc01c" ; Enter
; ========== Order Functions ==========
genericItem(items, threshold) { ; detects both the side or drink, combined because smaller
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-140 "|" windowY+(windowHeight/2)-300 "|290|185")
    item := []
    for i in items
        if (Gdip_ImageSearch(pBMScreen, bitmaps[i],,,,,,threshold))
            item.Push(i)
    Gdip_DisposeImage(pBMScreen)
    if item.Length > 0 {
        while (size := itemSize()) = 0 || A_Index > 9
            Sleep 100
        item.Push(size)
    }
    return (item.Length > 0) ? item : 0
}
sideItem() => genericItem(["fries", "sticks", "rings"], 60)
drinkItem() => genericItem(["drink", "juice", "shake"], 75)
itemSize() { ; 3=large, 2=medium, 1=small, 0=none
    pBMScreen := Gdip_BitmapFromScreen(windowX+968 "|" windowY+360 "|46|46")
    size := (Gdip_ImageSearch(pBMScreen, bitmaps["large"],,,,,,5) ? "large" : Gdip_ImageSearch(pBMScreen, bitmaps["medium"],,,,,,5) ? "medium" : (Gdip_ImageSearch(pBMScreen, bitmaps["small"],,,,,,5) ? "small" : 0))
    Gdip_DisposeImage(pBMScreen)
    return size
}
burgerItem() { ; returns array of each topping, 0 if nothing was detected
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-500 "|" windowY+(windowHeight/2)-300 "|900|185")
    items := [], threshold := [20,50,10,10,10,45]
    for item in ["lettuce", "tomato", "beef", "veggie", "cheese", "onion"]
        if (Gdip_ImageSearch(pBMScreen, bitmaps[item],&coords,,,,,threshold[A_Index]))
            items.Push([item, toppingAmount(coords)])
    Gdip_DisposeImage(pBMScreen)
    return (items.Length > 0) ? items : 0
}
toppingAmount(coords) { ; just used by burgerItems(), detects the amount of one topping in a burger
    x:=StrSplit(coords,",")[1]
    pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/2)-500+x "|" windowY+370 "|100|100")
    amount := (Gdip_ImageSearch(pBMScreen, bitmaps["2"],,,,,,20) ? 2 : 1)
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
    if (Gdip_ImageSearch(pBMScreen, bitmaps["question"],,,,,,15)) || ran>=30
        isEnd := 1, ran:=0
    Gdip_DisposeImage(pBMScreen)
    return isEnd
}
orderBuilder() { ; 
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
    sleep 3000 ; gives a delay until it starts again (safety)
}
buildBurger(order) { ; builds the whole burger.
    if !order
        return
    ClickAt(1858, 380) ; burger builder
    Sleep 500
    ClickAt(1665, 745) ; bottom bun
    for item in order {
        y:=Map("lettuce", 685, "tomato", 600, "beef", 540, "veggie", 540, "cheese", 475, "onion", 410), name:=item[1], amount:=item[2]
        Loop amount
            Sleep((A_Index = 1) ? 100 : 250), ClickAt((name = "beef") ? 1616: (name = "veggie") ? 1700 : 1665, y[name])
    }
    ClickAt(1665, 350) ; top bun
}
buildGeneric(itemType, order) { ; builds both the side or drink, combined because smaller
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
ClickAt(x, y) => (MouseMove(x+Random(-20,20)+windowX, y+Random(-8,10)+windowY, 4),Click("Down"),Click("Up"),0)
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
    if (WindowWidth!=1920 || windowHeight!=1080)
        msgbox("Roblox will be automatically scaled to 1920x1080"), ForceRoblox1080p()
    start := nowUnix()
    while (nowUnix()-start < timeLimit)
        GetRobloxClientPos(),orderBuilder(), Sleep(100)
    closeRoblox(), ExitApp()
}
F2::Reload
F3::ExitApp
