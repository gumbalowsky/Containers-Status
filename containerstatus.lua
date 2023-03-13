local PLUGIN = PLUGIN
PLUGIN.name = "Containers Status"
PLUGIN.author = "Gumbalowsky"
PLUGIN.description = "Displays the status of being in inventory above character's head."


if (SERVER) then

    util.AddNetworkString("ixContainerStatusClass")

    function PLUGIN:PlayerSpawn(client)

        net.Start("ixContainerStatusClass")
            net.WriteEntity(client)
            net.WriteBool(false)
        net.Broadcast() 

    end


    net.Receive("ixContainerStatusClass", function(len, client)

        local ent = net.ReadEntity() or client
        local netBool = net.ReadBool() or false
        local txtType = net.ReadInt(4) or 1

        net.Start("ixContainerStatusClass")
        net.WriteEntity(client)
        net.WriteBool(netBool)
        net.WriteInt(txtType, 4)

        if(!netBool) then
            net.Broadcast()
        else
            net.SendPVS(client:GetPos())
        end

    end)

end


if (CLIENT) then

    local standingOffset = Vector(0, 0, 72)
	local crouchingOffset = Vector(0, 0, 38)
	local boneOffset = Vector(0, 0, 10)
	local textColor = Color(250, 250, 250)
	local shadowColor = Color(66, 66, 66)

    net.Receive("ixContainerStatusClass", function()

        local client = net.ReadEntity()
        local status = net.ReadBool()
        local txtType = net.ReadInt(4) or 1

        if (!IsValid(client) or client == LocalPlayer()) then
			return
		end

        client.ixContainerStatusBool = status
        if(txtType == 1) then
            client.ixContainerStatusText = "In Inventory..."
        elseif(txtType == 2) then
            client.ixContainerStatusText = "Searching..."
        end
        
    end)


    // -- Drawing section:

    function PLUGIN:LoadFonts(font, genericFont)
        surface.CreateFont("ixConStatusIndicator", {
            font = genericFont,
            size = 64,
            extended = true,
            weight = 1000
        })
    end
    
    function PLUGIN:GetTypingIndicatorPosition(client)
        local head
    
        for i = 1, client:GetBoneCount() do
            local name = client:GetBoneName(i)
    
            if (string.find(name:lower(), "head")) then
                head = i
                break
            end
        end
    
        local position = head and client:GetBonePosition(head) or (client:Crouching() and crouchingOffset or standingOffset)
        return position + boneOffset
    end
    
    function PLUGIN:PostDrawTranslucentRenderables()
    
        local client = LocalPlayer()
        local position = client:GetPos()
        
        for _, v in ipairs(player.GetAll()) do

            if (v == client) then
                continue
            end
    
            local distance = v:GetPos():DistToSqr(position)
            local moveType = v:GetMoveType()
            local range = math.pow(ix.config.Get("chatRange", 280), 2)

            if (!IsValid(v) or !v:Alive() or
                (moveType != MOVETYPE_WALK and moveType != MOVETYPE_NONE) or
                !v.ixContainerStatusBool or
                distance >= range) then
                continue
            end

            local fraction = 1
            local text = v.ixContainerStatusText
            local angle = EyeAngles()
            
            angle:RotateAroundAxis(angle:Forward(), 90)
            angle:RotateAroundAxis(angle:Right(), 90)
    
            cam.Start3D2D(self:GetTypingIndicatorPosition(v), Angle(0, angle.y, 90), 0.05)
                surface.SetFont("ixConStatusIndicator")
    
                local _, textHeight = surface.GetTextSize(text)
                local alpha = bAnimation and ((1 - math.min(distance, range) / range) * 255 * fraction) or 255
    
                draw.SimpleTextOutlined(text, "ixConStatusIndicator", 0,
                    -textHeight * 0.5 * fraction,
                    ColorAlpha(textColor, alpha),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER, 4,
                    ColorAlpha(shadowColor, alpha)
                )
            cam.End3D2D()

        end
    
    end

end

