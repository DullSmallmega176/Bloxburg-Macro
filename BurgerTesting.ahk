#MaxThreads 255
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
            ClickAt(1660, 685)
        case "tomato":
            ClickAt(1660, 610)
        case "beef":
            ClickAt(1616, 538) 
        case "veggie":
            ClickAt(1702, 538) 
        case "cheese":
            ClickAt(1660, 474)
        case "onion":
            ClickAt(1660, 409)
        case "fries", "drink":
            ClickAt(1600, 420)
            ClickSize(size)
        case "sticks", "juice":
            ClickAt(1600, 544)
            ClickSize(size)
        case "rings", "shake":
            ClickAt(1600, 660)
            ClickSize(size)
        
    }
    if (times=2) {
        HyperSleep(250)
        Click "Down"
        Click "Up"
    }
}

FindSize() { ; this can probably be improved
    global bitmaps
    sizes:=["small","medium","large"], size:=""
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
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-500+x "|" ((windowY+windowHeight)/2)-300+y "|100|100")
    for i in amount {
        if (Gdip_ImageSearch(pBMScreen, bitmaps[i], , , , , , 20)) {
            Gdip_DisposeImage(pBMScreen)
            return i ; this is where it's clarified how many burger patties or toppings to add for the corresponding item
        }
    }
    Gdip_DisposeImage(pBMScreen)
    return 1 ; default if not detected, gamble
}

ClickSize(size) { ; didn't want to create a whole thing on the sides and drinks section
    switch size {
        case "small":
            ClickAt(1730, 420)
        case "medium":
            ClickAt(1730, 544)
        case "large":
            ClickAt(1730, 660)
        default: ; medium, this is a just in case if nothing is detected
        ClickAt(1730, 544)
    }
}

BurgerAction() { ; builds the whole burger
    global bitmaps
    detected:=0, TheOrder:= Map(), ItemsArray:=[], times:=0, t:=2500, itemarr:=["lettuce","tomato","beef","veggie","cheese","onion"], threshold:=[20,50,10,10,10,50]
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    ClickAt(1860, 370) 
    HyperSleep(300)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-500 "|" ((windowY+windowHeight)/2)-300 "|900|185")
    ; this can probably be improved
    for i in itemarr {
        if (Gdip_ImageSearch(pBMScreen, bitmaps[i], &Coords, , , , , threshold[A_Index]))
            coords:=StrSplit(Coords,","), BT:=FindAmount(coords[1],coords[2]), TheOrder.__New(i, BT), ItemsArray.Push(i), detected:=1, t:=(BT=2) ? t-250 : t-125
    }
    ; bottom bun
    if detected=1 { ; this one is different from the other ones
        ClickAt(1660, 745)
        ; the rest of the items
        for i in ItemsArray {
            ClickItem(i, TheOrder[i])
        }
        ; top bun
        ClickAt(1660, 333) 
        ; drinks section
        ClickAt(1860, 483) 
        HyperSleep(t)
    }
    FinishedOrder()
    Gdip_DisposeImage(pBMScreen)
    if detected=1
        return 1
}

SidesAction() { ; this also can absolutely get improved, this is for the sides (fries and whatever)
    global bitmaps, detected:=0, times:=0, sides:=["fries","sticks","rings"]
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-140 "|" ((windowY+windowHeight)/2)-300 "|290|185") 
    for i in sides {
        if (Gdip_ImageSearch(pBMScreen, bitmaps[i], , , , , , 60)) {
            detected:=1, size:=FindSize()
            ClickItem(i,,size)
            ClickAt(1860, 593)
            HyperSleep(1200)
            break
        }
    }
    FinishedOrder()
    Gdip_DisposeImage(pBMScreen)
    return detected
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
            drink:=i, detected:=1, size:=FindSize()
            ClickItem(drink,,size)
            HyperSleep(1000)
            break
        }
    }
    ClickAt(1860, 370)
    HyperSleep(100)
    FinishedOrder()
    Gdip_DisposeImage(pBMScreen)
    return detected
}

FinishedOrder() {
    static failed:=0
    HyperSleep(100)
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-500 "|" ((windowY+windowHeight)/2)-300 "|900|185")
    if (Gdip_ImageSearch(pBMScreen, bitmaps["question"], , , , , , 40) || ++failed>=6) { ; finished
        failed:=0
        ClickAt(1857,712)
        HyperSleep(1500)

    }
    tooltip failed
}

ClickAt(x, y) {
    MouseMove(x,y)
    Click "Down"
    Click "Up"
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
        HyperSleep(100)
    }
}
F2::Pause
F3::Reload
F4::ExitApp
