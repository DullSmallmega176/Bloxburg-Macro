Class WebHookBuilder {
    __New(webhookURL) {
        if !(webhookURL ~= 'i)https?:\/\/discord\.com\/api\/webhooks\/(\d{18,19})\/[\w-]{68}')
            throw Error("invalid webhook URL", , webhookURL)
        this.webhookURL := webhookURL   
    }
    Call(method, options, urlOverride?) {
        defaultHeaders := {
            %"User-Agent"%: "DiscordBot (by Ninju)"
        }
        url := IsSet(urlOverride) ? urlOverride:this.webhookURL
        (whr := ComObject("WinHttp.WinHttpRequest.5.1")).Open(method, url, false)
        for i, j in defaultHeaders.OwnProps()
            whr.SetRequestHeader(i, j)
        for i, j in (options.hasProp("header") ? options.header : {}).OwnProps()
            whr.SetRequestHeader(i, j)
        if options.hasProp("body") {
            whr.Send(options.hasProp("body") ? ((IsObject(options.hasProp("body") ? options.body : "") && !(options.body is ComObjArray || options.body is FormData)) ? JSON.stringify(options.hasProp("body") ? options.body : "") : (options.body is FormData) ? (options.body).data() : options.hasProp("body") ? options.body : "") : "")
        }
        return { status: whr.Status, text: whr.ResponseText, json: JSON.parse(whr.ResponseText) }
    }
    Send(obj) {
        contentType := "application/json"
        if obj.HasProp("embeds") {
            embeds := []
            for _, embed in obj.embeds {
                embeds.Push(embed is EmbedBuilder ? embed.embedObj : embed)
            }
            obj.embeds := embeds
        }
        if obj.HasProp("files") {
            form := FormData()
            for i, j in obj.files {
                if !j is AttachmentBuilder
                    throw Error("expected AttachmentBuilder")
                if j.isBitmap
                    form.AppendBitmap(j.file, j.fileName)
                else
                    form.AppendFile(j.file, j.contentType)
                obj.files[i] := j.attachmentName
            }
            form.AppendJSON("payload_json", { content: obj.HasProp("content") ? obj.content : "", embeds: obj.HasProp("embeds") ? obj.embeds : [], files: obj.files })
            return this.Call("POST", { header: { %"Content-Type"%: form.contentType }, body: form }, this.webhookURL "?wait=true")
        }
        return this.Call("POST", { header: { %"Content-Type"%: contentType }, body: obj }, this.webhookURL "?wait=true")
    }
    EditMessage(messageId, content) {
        contentType := "application/json"
        if content.hasProp("embeds") {
            embeds := []
            for i, j in content.embeds {
                if j is EmbedBuilder
                    embeds.Push(j.embedObj)
                else embeds.Push(j)
            }
            content.embeds := embeds
        }
        url := this.webhookURL "/messages/" messageId
        return this.Call("PATCH", {
            header: { %"Content-Type"%: contentType },
            body: content
        }, url)
    }
}
