local DoorFramework = {}

DoorFramework.scriptName = "DoorFramework"

DoorFramework.defaultConfig = {
    cmdStaffRank = 1,
    collision = true,
    cmd = "dfw",
    sound = "fx/doorw1.wav"
}

DoorFramework.config = DataManager.loadConfiguration(DoorFramework.scriptName, DoorFramework.defaultConfig)

DoorFramework.defaultData = {
    records = {},
    refIdMap = {}
}

DoorFramework.data = DataManager.loadData(DoorFramework.scriptName, DoorFramework.defaultData)

DoorFramework.cmd = {}


function DoorFramework.createRecord(recordId, name, model, cellDescription, location, sound)
    local recordStore = RecordStores["miscellaneous"]

    local refId = recordStore:GenerateRecordId()
    recordStore.data.generatedRecords[refId] = {
        name = name,
        model = model,
        script = "noPickUp"
    }
    recordStore:Save()

    if DoorFramework.config.collision then
        table.insert(config.enforcedCollisionRefIds, refId)
        local player = tableHelper.getAnyValue(Players)
        if player ~= nil then
            logicHandler.SendConfigCollisionOverrides(player.pid, true)
        end
    end

    local record = {
        refId = refId,
        location = location,
        cellDescription = cellDescription,
        sound = sound
    }

    DoorFramework.data.records[recordId] = record
    DoorFramework.data.refIdMap[refId] = recordId
    return recordId
end

function DoorFramework.getRecord(recordId)
    return DoorFramework.data.records[recordId]
end

function DoorFramework.removeRecord(recordId)
    DoorFramework.data.records[recordId] = nil
end



function DoorFramework.spawnDoor(recordId, cellDescription, location)
    local record = DoorFramework.getRecord(recordId)
    logicHandler.CreateObjectAtLocation(cellDescription, location, record.refId, "place")
end

function DoorFramework.isDoor(refId)
    return DoorFramework.data.refIdMap[refId] ~= nil
end

function DoorFramework.getDoor(refId)
    return DoorFramework.data.refIdMap[refId]
end

function DoorFramework.useDoor(pid, recordId)
    local record = DoorFramework.getRecord(recordId)

    if record.sound ~= nil then
        tes3mp.PlaySpeech(pid, record.sound)
    end

    tes3mp.SetCell(pid, record.cellDescription)
    tes3mp.SendCell(pid)

    tes3mp.SetRot(
        pid,
        record.location.rotX,
        record.location.rotZ
    )
    tes3mp.SetPos(
        pid,
        record.location.posX,
        record.location.posY,
        record.location.posZ
    )
    tes3mp.SendPos(pid)
end


function DoorFramework.OnServerPostInit()
    if DoorFramework.config.collision then
        for recordId, record in pairs(DoorFramework.data.records) do
            table.insert(config.enforcedCollisionRefIds, record.refId)
        end
    end
end

function DoorFramework.OnServerExit()
    DataManager.saveData(DoorFramework.scriptName, DoorFramework.data)
end

function DoorFramework.OnObjectActivateV(eventStatus, pid, cellDescription, objects, players)
    if not eventStatus.validDefaultHandler then
        return
    end
    for _, object in pairs(objects) do
        local recordId = DoorFramework.getDoor(object.refId)
        if recordId ~= nil then
            DoorFramework.useDoor(pid, recordId)
            return customEventHooks.makeEventStatus(false, nil)
        end
    end
end

customEventHooks.registerHandler("OnServerPostInit", DoorFramework.OnServerPostInit)
customEventHooks.registerHandler("OnServerExit", DoorFramework.OnServerExit)
customEventHooks.registerValidator("OnObjectActivate", DoorFramework.OnObjectActivateV)


local mergeCmd = function(cmd, start)
    return table.concat(cmd, " ", start)
end

local toNumberCmd = function(cmd, start, finish)
    for i = start, finish do
        cmd[i] = tonumber(cmd[i])
        if cmd[i] == nil then
            return false
        end
    end
    return true
end

local messageCmdUsage = function(pid, msg)
    tes3mp.SendMessage(pid, string.format(msg, DoorFramework.config.cmd))
end

function DoorFramework.cmdRecord(pid, cmd)
    if Players[pid].data.settings.staffRank >= DoorFramework.config.cmdStaffRank then
        if DoorFramework.cmd[pid] == nil then
            DoorFramework.cmd[pid] = {}
        end

        if cmd[2] == "reset" then
            DoorFramework.cmd[pid] = {}
            messageCmdUsage(pid, "Door record parameters have been reset.\n")

        elseif cmd[2] == "pos" then
            if not toNumberCmd(cmd, 3, 5) then
                messageCmdUsage(pid, "Command usage: /%s pos <X> <Y> <Z>\n")
                return
            end

            DoorFramework.cmd[pid].position = {
                posX = cmd[3],
                posY = cmd[4],
                posZ = cmd[5]
            }

        elseif cmd[2] == "rot" then
            if not toNumberCmd(cmd, 3, 4) then
                messageCmdUsage(pid, "Command usage: /%s rot <X> <Z>\n")
                return
            end

            DoorFramework.cmd[pid].rotation = {
                rotX = cmd[3],
                rotZ = cmd[4]
            }

        elseif cmd[2] == "cell" then
            local cellDescription = mergeCmd(cmd, 3)
            DoorFramework.cmd[pid].cellDescription = cellDescription

        elseif cmd[2] == "name" then
            local name = mergeCmd(cmd, 3)
            DoorFramework.cmd[pid].name = name

        elseif cmd[2] == "model" then
            local model = mergeCmd(cmd, 3)
            DoorFramework.cmd[pid].model = model

        elseif cmd[2] == "sound" then
            local sound = nil
            if cmd[3] == nil then
                sound = DoorFramework.config.sound
            else
                sound = mergeCmd(cmd, 3)
            end

            DoorFramework.cmd[pid].sound = sound

        elseif cmd[2] == "create" then
            local recordId = cmd[3]
            if recordId == nil then
                messageCmdUsage("Command usage: /%s create <recordId>\n")
                return
            end

            local param = DoorFramework.cmd[pid]

            if param.name == nil then
                messageCmdUsage(pid, "Name is not set!\n")
                return
            end

            if param.model == nil then
                messageCmdUsage(pid, "Model path is not set!\n")
                return
            end

            if param.rotation == nil then
                param.rotation = {
                    rotX = tes3mp.GetRotX(pid),
                    rotZ = tes3mp.GetRotZ(pid)
                }
            end

            local cellDescription = ""
            if param.cellDescription == nil then
                cellDescription = tes3mp.GetCell(pid)
            else
                cellDescription = param.cellDescription
            end

            local location = {}
            if param.position == nil then
                location.posX = tes3mp.GetPosX(pid)
                location.posY = tes3mp.GetPosY(pid)
                location.posZ = tes3mp.GetPosZ(pid)
            else
                location.posX = param.position.posX
                location.posY = param.position.posY
                location.posZ = param.position.posZ
            end

            if param.rotation == nil then
                location.rotX = tes3mp.GetRotX(pid)
                location.rotZ = tes3mp.GetRotZ(pid)
            else
                location.rotX = param.rotation.rotX
                location.rotZ = param.rotation.rotZ
            end

            DoorFramework.createRecord(recordId, param.name, param.model, cellDescription, location, param.sound)

            tes3mp.SendMessage(pid, string.format("Created door record with id %s!\n", recordId))

        elseif cmd[2] == "remove" then
            if cmd[3] == nil then
                messageCmdUsage(pid, "Command usage: /%s create <recordId>\n")
                return
            end

            local recordId = cmd[3]
            DoorFramework.removeRecord(recordId)

        elseif cmd[2] == "spawn" then
            if cmd[3] == nil then
                messageCmdUsage(pid, "Command usage: /%s spawn <recordId>\n")
            end

            local recordId = cmd[3]
            if DoorFramework.getRecord(recordId) == nil then
                messageCmdUsage(pid, "Wrong id!\n")
                return
            end

            DoorFramework.spawnDoor(
                recordId,
                tes3mp.GetCell(pid),
                {
                    posX = tes3mp.GetPosX(pid),
                    posY = tes3mp.GetPosY(pid),
                    posZ = tes3mp.GetPosZ(pid),

                    rotX = 0,--tes3mp.GetRotX(pid),
                    rotY = 0,
                    rotZ = tes3mp.GetRotZ(pid)
                }
            )
        else
            messageCmdUsage(pid, "Command format: /%s <reset/pos/rot/cell/name/base/create/spawn>\n")
        end
    end
end

customCommandHooks.registerCommand(DoorFramework.config.cmd, DoorFramework.cmdRecord)