Class REST {
    __New(token, version?, guildId?) {
        this.token := token, this.version := version ?? 10, this.baseAPI := 'https://discord.com/api/v' this.version '/'
        this.defaultHeaders := {
            Authorization: "Bot " this.token, %"User-Agent"%: "DiscordBot (by Ninju)"
        }
        this.applicationId := this.getApplicationId()
        this.guildId := IsSet(guildId)?guildId:JSON.Null
    }
    Call(method, endpoint, options) {
        (whr := ComObject("WinHttp.WinHttpRequest.5.1")).Open(method, this.baseAPI . endpoint, false)
        for i, j in this.defaultHeaders.OwnProps()
            whr.SetRequestHeader(i, j)
        for i, j in (options.headers ?? {}).OwnProps()
            whr.SetRequestHeader(i, j)
        whr.Send(options.hasProp("body") ? ((IsObject(options.body ?? "") && !(options.body is ComObjArray || options.body is FormData)) ? JSON.stringify(options.body ?? "") : (options.body is FormData) ? (options.body).data() : options.body ?? "") : "")
        return { status: whr.Status, text: whr.ResponseText }
    }
    Get(endpoint, options) {
        return this.Call("GET", endpoint, options)
    }
    Post(endpoint, options) {
        return this.Call("POST", endpoint, options)
    }
    Patch(endpoint, options) {
        return this.Call("PATCH", endpoint, options)
    }
    Put(endpoint, options) {
        return this.Call("PUT", endpoint, options)
    }
    Delete(endpoint, options) {
        return this.Call("DELETE", endpoint, options)
    }
    getApplicationId() {
        res := this("GET", "oauth2/applications/@me", {})
        if res.status != 200
            throw Error("Failed to fetch application ID: " res.status " - " res.text)
        return JSON.parse(res.text)["id"]
    }
    SendMessage(channelId, content) {
        if content.hasProp("embeds") {
            embeds := []
            for i, j in content.embeds {
                if j is EmbedBuilder
                    embeds.Push(j.embedObj)
                else embeds.Push(j)
            }
            content.embeds := embeds
        }
        if content.hasProp("components") {
            components := []
            for i, j in content.components {
                if j is ActionRowBuilder
                    components.Push(j.actionRow)
                else components.Push(j)
            }
            content.components := components
        }
        if content.hasProp("files") {
            form := FormData()
            for i, j in content.files {
                if !j is AttachmentBuilder
                    throw Error("expected AttachmentBuilder")
                if j.isBitmap
                    form.AppendBitmap(j.file, j.fileName)
                else form.AppendFile(j.file, j.contentType)
                content.files[i] := j.attachmentName
            }
            form.AppendJSON("payload_json", { content: content.hasProp("content") ? content.content : "", embeds: embeds ?? [], files: [], components: components ?? []})
            contentType := form.contentType, body := form.data()
        }

        return this("POST", "channels/" channelId "/messages", {
            body: body ?? content,
            headers: { %"Content-Type"%: contentType ?? "application/json" }
        })
    }
    EditMessage(channelId, messageId, content) {
        if content.hasProp("embeds") {
            embeds := []
            for i, j in content.embeds {
                if j is EmbedBuilder
                    embeds.Push(j.embedObj)
                else embeds.Push(j)
            }
            content.embeds := embeds
        }
        if content.hasProp("components") {
            components := []
            for i, j in content.components {
                if j is ActionRowBuilder
                    components.Push(j.actionRow)
                else components.Push(j)
            }
            content.components := components
        }
        return this("PATCH", "channels/" channelId "/messages/" messageId, {
            body: content,
            headers: { %"Content-Type"%: "application/json" }
        })
    }
    __Call(method, endpoint, options) {
        return this.Call(method, endpoint, options)
    }
    createSlashCommand(command) {
        if !command is SlashCommandBuilder
            throw Error("expected SlashCommandBuilder but instead got a " Type(command))
        if !command.commandObject.hasProp("name") || !command.commandObject.name || !command.commandObject.hasProp("description") || !command.commandObject.description
            throw Error("name and description are required")
        return this("POST", (command.guildId && command.guildId != JSON.null) ? "applications/" this.applicationId "/guilds/" command.guildId "/commands" : "applications/" this.applicationId "/commands", {
            body: command.commandObject,
            headers: { %"Content-Type"%: "application/json" }
        })
    }
    removeSlashCommand(commandId, guildId:=JSON.null) => this("DELETE", (guildId && guildId != JSON.null) ? "applications/" this.applicationId "/guilds/" guildId "/commands/" commandId : "applications/" this.applicationId "/commands/" commandId, {})
    listSlashCommands(guildID := JSON.null) {
        endpoint := (guildId && guildId != JSON.null) ? "applications/" this.applicationId "/guilds/" guildId "/commands" : "applications/" this.applicationId "/commands"
        res := this("GET", endpoint, {})
        if res.status != 200
            throw Error("Failed to list commands: " res.status " - " res.text)
        return JSON.parse(res.text)
    }
    deleteAllSlashCommands() { ; sleeps are to not reach the API limit
        for _, cmd in this.listSlashCommands()
            this.removeSlashCommand(cmd["id"]), Sleep(100)
        for _, cmd in this.listSlashCommands(this.guildId)
            this.removeSlashCommand(cmd["id"], this.guildId), Sleep(100)
    }
}
