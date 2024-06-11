﻿#MaxThreads 255
#Requires AutoHotkey v2.0
#SingleInstance Force
/*
niche stuff
*/

; libraries
#Include "%A_ScriptDir%\lib"
#Include "Gdip_All.ahk"
#Include "Gdip_ImageSearch.ahk"
#Include "Roblox.ahk"
#Include "HyperSleep.ahk"
/*
each library is documented with it's original creator
except for HyperSleep.ahk, this was gotten from natro macro
so that's the only lead that i actually have
*/
; paths
#Include "%A_ScriptDir%\paths"
#Include "paths.ahk"

pToken := Gdip_Startup()

CoordMode "Mouse", "Screen"
CoordMode "Pixel", "Screen"
SendMode "Event"
if (A_ScreenDPI != 96) {
	MsgBox "it seems like your scale isn't 100%, this will break the macro, and also this macro is only limited to 1920x1080"
    Reload
}
section:=""
x:=0
; bitmaps
bitmaps := Map(), bitmaps.CaseSense := 0
#Include "%A_ScriptDir%\images"
#Include "bitmaps.ahk"
msgbox "loaded"
;;;;;
; FUNCTIONS
;;;;;
ClickItem(item, times:=0, size:="") { ; times is only used for burger toppings, size is only used for sides and drinks
    switch item {
        case "lettuce":
            loop times {
                MouseMove(1660, 685)
                Click "Down"
                HyperSleep(100)
                Click "Up"
                HyperSleep(150)
            }

        case "tomato":
            loop times {
                MouseMove(1660, 610)
                Click "Down"
                HyperSleep(100)
                Click "Up"
                HyperSleep(150)
            }
        case "beef":
            loop times {
                MouseMove(1616, 538)
                Click "Down"
                HyperSleep(100)
                Click "Up"
                HyperSleep(150)
            }
        case "veggie":
            loop times {
                MouseMove(1702, 538)
                Click "Down"
                HyperSleep(100)
                Click "Up"
                HyperSleep(150)
            }
        case "cheese":
            loop times {
                MouseMove(1660, 474)
                Click "Down"
                HyperSleep(100)
                Click "Up"
                HyperSleep(150)
            }
        case "onion":
            loop times {
                MouseMove(1660, 409)
                Click "Down"
                HyperSleep(100)
                Click "Up"
                HyperSleep(150)
            }
        case "fries", "drink":
            MouseMove(1600, 420)
            Click "Down"
            HyperSleep(100)
            Click "Up"
            HyperSleep(150)
            ClickSize(size)
        case "sticks", "juice":
            MouseMove(1600, 544)
            Click "Down"
            HyperSleep(100)
            Click "Up"
            HyperSleep(150)
            ClickSize(size)
        case "rings", "shake":
            MouseMove(1600, 660)
            Click "Down"
            HyperSleep(100)
            Click "Up"
            HyperSleep(150)
            ClickSize(size)
        
    }
}
FindSize() { ; this can probably be improved
    global bitmaps
    sizes:=["small","medium","large"]
    size:=""
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-140 "|" ((windowY+windowHeight)/2)-300 "|290|185") ; getting a bitmap bigger than the order size, this is because it will always be changing
    for i in sizes {
        if (Gdip_ImageSearch(pBMScreen, bitmaps[i], , , , , , 10)) {
            size:=i
            break
        }
    }
    Gdip_DisposeImage(pBMScreen)
    return size
}

FindAmount(x, y) { ; this can probably be improved
    global bitmaps
    amount:=["1","2"]
    BigTotal:=0
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-500+x "|" ((windowY+windowHeight)/2)-300+y "|100|100")
    for i in amount {
        if (Gdip_ImageSearch(pBMScreen, bitmaps[i], , , , , , 20)) {
            BigTotal:=i ; this is where it's clarified how many burger patties or toppings to add for the corresponding item
        }
    }
    Gdip_DisposeImage(pBMScreen)
    return BigTotal
}

ClickSize(size) { ; didn't want to create a whole thing on the sides and drinks section
    switch size {
        case "small":
            MouseMove(1730, 420)
            Click "Down"
            HyperSleep(100)
            Click "Up"
            HyperSleep(150)
        case "medium":
            MouseMove(1730, 544)
            Click "Down"
            HyperSleep(100)
            Click "Up"
            HyperSleep(150)
        case "large":
            MouseMove(1730, 660)
            Click "Down"
            HyperSleep(100)
            Click "Up"
            HyperSleep(150)
        default: ; medium, this is a just in case if nothing is detected
            MouseMove(1730, 544)
            Click "Down"
            HyperSleep(100)
            Click "Up"
            HyperSleep(150)
    }
}
BurgerAction() { ; builds the whole burger
    global bitmaps
    detected:=0
    TheOrder:= Map()
    ItemsArray:=[]
    times:=0
    t:=2100
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    HyperSleep(200)
    MouseMove(1860, 370) ; this is because of reliablility stuff
    Click "Down"
    HyperSleep(100)
    Click "Up"
    HyperSleep(300)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-500 "|" ((windowY+windowHeight)/2)-300 "|900|185")
    /*
    THIS CAN ABSOLUTELY GET IMPROVED, but some items wanted to be special so i just gave up
    and brute forced it, but it works EMMACULATE tho
    */
    if (Gdip_ImageSearch(pBMScreen, bitmaps["lettuce"], &Coords, , , , , 20)) {
        t:=t-300
        coords := StrSplit(Coords,",")
        BigTotal := FindAmount(coords[1],coords[2])
        TheOrder.__New("lettuce", BigTotal)
        ItemsArray.Push("lettuce")
        
    }
    if (Gdip_ImageSearch(pBMScreen, bitmaps["tomato"], &Coords, , , , , 50)) {
        t:=t-300
        coords := StrSplit(Coords,",")
        BigTotal := FindAmount(coords[1],coords[2])
        TheOrder.__New("tomato", BigTotal)
        ItemsArray.Push("tomato")
    }
    if (Gdip_ImageSearch(pBMScreen, bitmaps["beef"], &Coords, , , , , 10)) {
        t:=t-300
        coords := StrSplit(Coords,",")
        BigTotal := FindAmount(coords[1],coords[2])
        TheOrder.__New("beef", BigTotal)
        ItemsArray.Push("beef")
        detected:=1
    }
    if (Gdip_ImageSearch(pBMScreen, bitmaps['veggie'], &Coords, , , , , 10)) {
        t:=t-300
        coords := StrSplit(Coords,",")
        BigTotal := FindAmount(coords[1],coords[2])
        TheOrder.__New("veggie", BigTotal)
        ItemsArray.Push("veggie")
        detected:=1
    }
    if (Gdip_ImageSearch(pBMScreen, bitmaps["cheese"], &Coords, , , , , 10)) {
        t:=t-300
        coords := StrSplit(Coords,",")
        BigTotal := FindAmount(coords[1],coords[2])
        TheOrder.__New("cheese", BigTotal)
        ItemsArray.Push("cheese")
    }
    if (Gdip_ImageSearch(pBMScreen, bitmaps["onion"], &Coords, , , , , 50)) {
        t:=t-300
        coords := StrSplit(Coords,",")
        BigTotal := FindAmount(coords[1],coords[2])
        TheOrder.__New("onion", BigTotal)
        ItemsArray.Push("onion")
    }
    ; bottom bun
    if detected=1 {
        MouseMove(1660, 745)
        Click "Down"
        HyperSleep(100)
        Click "Up"
        HyperSleep(100)
        ; the rest of the items
        for i in ItemsArray {
            ClickItem(i, TheOrder[i])
        }
        ; top bun
        MouseMove(1660, 333)
        Click "Down"
        HyperSleep(100)
        Click "Up"
        HyperSleep(100)
        ; drinks section
        MouseMove(1860, 483)
        Click "Down"
        HyperSleep(100)
        Click "Up"
        HyperSleep(t)
    }
    FinishedOrder()
    Gdip_DisposeImage(pBMScreen)
    if detected=1
        return 1
}

SidesAction() { ; this also can absolutely get improved, this is for the sides (fries and whatever)
    global bitmaps
    detected:=0
    times:=0
    sides:=["fries","sticks","rings"]
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-140 "|" ((windowY+windowHeight)/2)-300 "|290|185") 
    for i in sides {
        if (Gdip_ImageSearch(pBMScreen, bitmaps[i], , , , , , 60)) {
            side:=i
            detected:=1
            break
        }
    }
    if detected=1 {
        size:=FindSize()
        ClickItem(side,,size)
        MouseMove(1860, 593)
        Click "Down"
        HyperSleep(100)
        Click "Up"
        HyperSleep(1000)
    }
    FinishedOrder()
    Gdip_DisposeImage(pBMScreen)
    if detected=1
        return 1
}

DrinkAction() { ; same issue as the burger, things want to be special
    global bitmaps
    detected:=0
    drinks:=["drink","juice","shake"]
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-140 "|" ((windowY+windowHeight)/2)-300 "|290|185")
    for i in drinks {
        if (Gdip_ImageSearch(pBMScreen, bitmaps[i], , , , , , 60)) {
            drink:=i
            detected:=1
            break
        }
    }
    if detected=1 {
        size:=FindSize()
        ClickItem(drink,,size)
        HyperSleep(1000)
    }
    MouseMove(1860, 370)
    Click "Down"
    HyperSleep(100)
    Click "Up"
    HyperSleep(100)
    FinishedOrder()
    Gdip_DisposeImage(pBMScreen)
    if detected=1
        return 1
}
FinishedOrder() {
    static failed:=0
    HyperSleep(100)
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-500 "|" ((windowY+windowHeight)/2)-300 "|900|185")
    if (Gdip_ImageSearch(pBMScreen, bitmaps["question"], , , , , , 17) || failed=50) { ; finished
        failed:=0
        MouseMove(1857,712)
        Click "Down"
        HyperSleep(100)
        Click "Up"
        HyperSleep(1500)

    }else{
        failed++
    }
}
;;;;;
; HOTKEYS
;;;;;

F1::{
    loop {
        HyperSleep(100)
        BurgerAction()
        SidesAction()
        DrinkAction()
        HyperSleep(300)
    }
}
F2::Pause
F3::Reload
F4::ExitApp
