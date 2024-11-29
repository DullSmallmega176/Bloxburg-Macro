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
    if (times=2)
        HyperSleep(250),Click()
}

FindSize() { ; this can probably be improved
    global bitmaps
    size:=""
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-140 "|" ((windowY+windowHeight)/2)-300 "|290|185") ; getting a bitmap bigger than the order size, this is because it will always be changing
    for i in ["small","medium","large"] {
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
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-500+x "|" ((windowY+windowHeight)/2)-300+y "|100|100")
    for i in ["1","2"] {
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
    local detected:=0
    if FinishedOrder()=0 {
        TheOrder:= Map(), ItemsArray:=[], times:=0, t:=2500, threshold:=[20,50,10,10,10,50]
        ActivateRoblox()
        hwnd:=GetRobloxHWND()
        GetRobloxClientPos(hwnd)
        ClickAt(1860, 370) 
        HyperSleep(300)
        pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-500 "|" ((windowY+windowHeight)/2)-300 "|900|185")
        ; shuffling the list - later feature
        
        ; this can probably be improved
        for i in ["lettuce","tomato","beef","veggie","cheese","onion"] {
            if (Gdip_ImageSearch(pBMScreen, bitmaps[i], &Coords, , , , , threshold[A_Index]))
                coords:=StrSplit(Coords,","), BT:=FindAmount(coords[1],coords[2]), TheOrder.__New(i, BT), ItemsArray.Push(i), detected:=1, t:=(BT=2) ? t-=250 : t-=142
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
            Gdip_DisposeImage(pBMScreen)
            return 1
        }
        Gdip_DisposeImage(pBMScreen)
    }
    return 0
}

SidesAction() { ; this also can absolutely get improved, this is for the sides (fries and whatever)
    global bitmaps
    if FinishedOrder()=0 {
        detected:=0, times:=0
        ActivateRoblox()
        hwnd:=GetRobloxHWND()
        GetRobloxClientPos(hwnd)
        pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-140 "|" ((windowY+windowHeight)/2)-300 "|290|185") 
        for i in ["fries","sticks","rings"] {
            if (Gdip_ImageSearch(pBMScreen, bitmaps[i], , , , , , 60)) {
                size:=FindSize()
                ClickItem(i,,size)
                ClickAt(1860, 593)
                HyperSleep(1200)
                break
            }
        }
        Gdip_DisposeImage(pBMScreen)
        return 1
    }
    return 0
}

DrinkAction() { ; same issue as the burger, things want to be special
    global bitmaps
    if FinishedOrder()=0 {
        ActivateRoblox()
        hwnd:=GetRobloxHWND()
        GetRobloxClientPos(hwnd)
        pBMScreen := Gdip_BitmapFromScreen(((windowX+windowWidth)/2)-140 "|" ((windowY+windowHeight)/2)-300 "|290|185")
        for i in ["drink","juice","shake"] {
            if (Gdip_ImageSearch(pBMScreen, bitmaps[i], , , , , , 60)) {
                drink:=i, size:=FindSize()
                ClickItem(drink,,size)
                HyperSleep(1000)
                break
            }
        }
        ClickAt(1860, 370)
        HyperSleep(100)
        Gdip_DisposeImage(pBMScreen)
        return 1
    }
    return 0
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
        HyperSleep(2000)
        return 1
    }
    tooltip failed
    return 0
}

ClickAt(x, y) {
    MouseMove(x+Random(-20,20),y+Random(-10,10))
    Click "Down"
    Click "Up"
}

RotateCamera(direction:=0, amount:=0) { ; direction, left:=1, right:=0, amount can be a decimal, but it has to be a number divisible by 48
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    MouseMove((windowX+windowWidth)/2, (windowY+windowHeight)/2)
    MouseGetPos(&xx,&yy)
    Click "Down R"
    sleep 100
    loop round(48*amount) {
        if !(direction=1)
            DllCall("user32.dll\mouse_event", "UInt", 0x0001, "Int", 5, "Int", 0)
        else
            DllCall("user32.dll\mouse_event", "UInt", 0x0001, "Int", -5, "Int", 0)
    }
    sleep 100
    Click "Up R"
    MouseMove(xx,yy)
}

CameraUp() { ; this can be done better but this is future proofing
    ActivateRoblox()
    hwnd:=GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    MouseMove((windowX+windowWidth)/2, (windowY+windowHeight)/2)
    Click "Down R"
    MouseGetPos(&xx,&yy)
    MouseMove(xx,yy+20)
    Click "Up R"
}

NextOrder() { ; check if you're in critical health, this will be implemented in the near idk how long
    return 0
}

;;;;;
; HOTKEYS
;;;;;
F1::{
    loop {
        BurgerAction()
        SidesAction()
        DrinkAction()
        HyperSleep(100)
    }
}
F2::Pause -1
F3::Reload
F4::ExitApp