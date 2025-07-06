/**
 * @description Just because the discord thing that ninju made is not ASYNC
 * @date 2025/07/03
 * @version 0.0.0
**/
#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Force
#MaxThreads 255
#Warn VarUnset, Off
OnError (e, mode) => (mode = "Return") ? -1 : 0
SetWorkingDir A_ScriptDir "\.."
CoordMode "Mouse", "Screen"
CoordMode "Pixel", "Screen"
SendMode "Event"

#Include "%A_ScriptDir%\..\lib"
#Include "FormData.ahk"
#Include "Gdip_All.ahk"
#Include "JSON.ahk"
#Include "QueryPerformance.ahk"
#Include "WebSockets.ahk"

#Include "%A_ScriptDir%\..\lib\Discord"
#Include "ActionRowBuilder.ahk"
#Include "AttachmentBuilder.ahk"
#Include "Client.ahk"
#Include "EmbedBuilder.ahk"
#Include "REST.ahk"
#Include "SlashCommandBuilder.ahk"
#Include "WebHookBuilder.ahk"

if (A_Args.Length = 0) {
    Msgbox "This file needs to be ran by bloxburg_macro.ahk. This script is not meant to be ran manually"
    ExitApp
}

if !(pToken := Gdip_Startup())
    throw Error("GDI+ failed to start, exiting script.")

OnExit(ExitFunc)
OnMessage(0xC2, setStatus)

(conf := Map()).CaseSense := 0
(settings := Map()).CaseSense := 0

conf["DiscordMode"] := A_Args[1]
conf["DiscordEnabled"] := A_Args[2]
conf["Webhook"] := A_Args[3]
conf["BotToken"] := A_Args[4]
conf["ChannelID"] := A_Args[5]
conf["GuildId"] := A_Args[6]

settings["Beef"] := {enum: 1,  type: "int", section: "Advanced", regex: "i)^([0-9]|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])$"}
settings["Cheese"] := {enum: 2,  type: "int", section: "Advanced", regex: settings["Beef"].regex}
settings["Drink"] := {enum: 3,  type: "int", section: "Advanced", regex: settings["Beef"].regex}
settings["Fries"] := {enum: 4,  type: "int", section: "Advanced", regex: settings["Beef"].regex}
settings["Juice"] := {enum: 5,  type: "int", section: "Advanced", regex: settings["Beef"].regex}
settings["Lettuce"] := {enum: 6,  type: "int", section: "Advanced", regex: settings["Beef"].regex}
settings["OffsetX"] := {enum: 7,  type: "int", section: "Advanced", regex: "i)^(0|[1-9]|1\d|20)$"}
settings["OffsetY"] := {enum: 8,  type: "int", section: "Advanced", regex: "i)^(0|[1-9]|1[0-5])$"}
settings["Onion"] := {enum: 9,  type: "int", section: "Advanced", regex: settings["Beef"].regex}
settings["OrderTimeout"]    := {enum: 10, type: "int", section: "Advanced", regex: "i)^([0-9]|[1-5]\d|60)$"}
settings["Rings"] := {enum: 11, type: "int", section: "Advanced", regex: settings["Beef"].regex}
settings["Shake"] := {enum: 12, type: "int", section: "Advanced", regex: settings["Beef"].regex}
settings["Sticks"] := {enum: 13, type: "int", section: "Advanced", regex: settings["Beef"].regex}
settings["Tomato"] := {enum: 14, type: "int", section: "Advanced", regex: settings["Beef"].regex}
settings["ToppingDelay1"] := {enum: 15, type: "int", section: "Advanced", regex: "i)^([0-9]|[1-9]\d{0,2}|1000)$"}
settings["ToppingDelay2"] := {enum: 16, type: "int", section: "Advanced", regex: settings["ToppingDelay1"].regex}
settings["Veggie"] := {enum: 17, type: "int", section: "Advanced", regex: settings["Beef"].regex}

settings["AlwaysOnTop"] := {enum: 18, type: "int", section: "Gui", regex: "i)^(0|1)$"}
settings["DarkMode"] := {enum: 19, type: "int", section: "Gui", regex: settings["AlwaysOnTop"].regex}
settings["DebugConsole"] := {enum: 20, type: "int", section: "Gui", regex: settings["AlwaysOnTop"].regex}

settings["AutoCloseRoblox"] := {enum: 21, type: "int", section: "Settings", regex: settings["AlwaysOnTop"].regex}
settings["ClickDelay"] := {enum: 22, type: "int", section: "Settings", regex: settings["ToppingDelay1"].regex}
settings["FinishOrderDelay"] := {enum: 23, type: "int", section: "Settings", regex: "i)^([0-9]|[1-9]\d{1,3}|5000)$"}
settings["ImageSearchDelay"] := {enum: 24, type: "int", section: "Settings", regex: settings["ToppingDelay1"].regex}
settings["timeLimMins"] := {enum: 25, type: "int", section: "Settings", regex: "i)^-1|[0-9]+$"}

settings["UserID"] := {enum: 26, type: "int", section: "Discord", regex: "i)^\d{17,20}$"}
settings["Webhook"] := {enum: 27, type: "str", section: "Discord", regex: "i)^(https:\/\/(canary\.|ptb\.)?(discord|discordapp)\.com\/api\/webhooks\/([\d]+)\/([a-z0-9_-]+)|<blank>)$"}

if conf["DiscordMode"] = "Webhook" && conf["DiscordEnabled"] {
    webhook := WebHookBuilder(conf["Webhook"])
} else if conf["DiscordMode"] = "Bot" && conf["DiscordEnabled"] {
    bot := REST(conf["BotToken"], 10, conf["GuildId"])
    builder := SlashCommandBuilder(conf["GuildId"]).setName("screenshot").setDescription("This sends a screenshot of your screen."), builder.addStringOption().setName("mode").setDescription("Choose which screen to capture").setRequired(false).addChoice("All", "all").addChoice("Window", "window").addChoice("Screen", "screen"), screenshot := bot.createSlashCommand(builder)
    get := bot.createSlashCommand(SlashCommandBuilder(conf["GuildId"]).setName("get").setDescription("Get a setting value from your config file"))
    set := bot.createSlashCommand(SlashCommandBuilder(conf["GuildId"]).setName("set").setDescription("Set a new value to a setting from your config file"))
    discord := client(intents.GUILDS | intents.GUILD_MESSAGES | intents.MESSAGE_CONTENT)
    discord.login(conf["BotToken"])
    discord.on("INTERACTION_CREATE", discordAction)
}
testing := sendDiscordMessage(EmbedBuilder().setTitle("Connected to Discord: " conf["DiscordMode"]).setColor(5066239).setTimeStamp())
discordAction(input, *) {
    global discord
    userInput := Interaction(discord, input)
    if userInput.isCommand && userInput.data.data.name = "screenshot" {
        try mode := userInput.getStringOption("mode") ?? "all"
        catch
            mode := "all"
        switch mode {
            case "all":
                pBMScreen := pBMScreen := Gdip_BitmapFromScreen()
            case "window":
                WinGetClientPos &x, &y, &w, &h, "A"
                if (w > 0)
                    pBMScreen := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
                else
                    pBMScreen := Gdip_BitmapFromScreen()
            case "screen":
                pBMScreen := Gdip_BitmapFromScreen(1)
            default:
                Gdip_BitmapFromScreen()
        }
        userInput.reply({ embeds: [EmbedBuilder().setTitle("Screenshot sent!").setColor(5066239).setTimeStamp().setImage(AttachmentBuilder(pBMScreen))], files: [AttachmentBuilder(pBMScreen)] })
        ; ^^^ ; why does it have to be like this :sob:
        Gdip_DisposeImage(pBMScreen)
    }
    if userInput.isCommand && userInput.data.data.name = "get" {
        userInput.reply({ content: "Currently not finished, too lazy to make it right now, I just want 0.3.0 finished" })
    }
    if userInput.isCommand && userInput.data.data.name = "set" {
        userInput.reply({ content: "Currently not finished, too lazy to make it right now, I just want 0.3.0 finished" })
    }
}
sendDiscordMessage(embed, *) {
    global conf, webhook, bot
    if !conf["DiscordEnabled"]
        return
    if conf["DiscordMode"] = "Webhook"
        return webhook.Send({embeds: [embed]})
    else if conf["DiscordMode"] = "Bot"
        return bot.SendMessage(conf["ChannelID"], {embeds: [embed]})
}
sendDiscordEdit(messageID, embed) {
    global bot, webhook
    if !conf["DiscordEnabled"]
        return
    if conf["DiscordMode"] = "Bot"
        bot.EditMessage(conf["ChannelID"], messageID, { embeds: [embed.embedObj] })
    else if conf["DiscordMode"] = "Webhook"
        webhook.EditMessage(messageID, { embeds: [embed.embedObj] })
}
setStatus(wParam, lParam, *) {
    static orderBuilt := 0, buildLog := ""

    try {
        msg := StrGet(lParam)
        if msg ~= "i)Burger|Side|Drink" {
            buildLog .= (buildLog ? "`n" : "") msg
            embed := EmbedBuilder().setTitle("Building Order...").setDescription(buildLog).setColor(wParam).setTimeStamp()
            if (InStr(msg, "Burger") && !orderBuilt) {
                result := sendDiscordMessage(embed)
                if (result.status = 200 || result.status = 201)
                    try orderBuilt := JSON.parse(result.text)["id"]
            }
            else if orderBuilt
                try sendDiscordEdit(orderBuilt, embed)
            return
        }
        buildLog := "", orderBuilt := 0
        sendDiscordMessage(EmbedBuilder().setTitle(msg).setColor(wParam).setTimeStamp())
    }
}
ExitFunc(*) {
    global discord, webhook, bot, pToken
    discord.setPresence({ status: "invisible" })
    try discord.__Delete()
    try webhook.__Delete()
    try bot.__Delete()
    try Gdip_Shutdown(pToken)
}

F14::msgbox "hi"
