local grabFrame = function(this, path, renderTexture)
    local feature = this:getFeature(path)
    if feature then
        feature = EffectSdk.castGeneralEffectFeature(feature)
        feature:pushCommandGrab(renderTexture, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0)
    end
end

local init_state = 1
local MOV_THRES = 0.0
local texKey = "MULTISRC_1_0"
local srcWidth = 720
local srcHeight = 1280

local oldTex = nil
local function remapTouchXY(this, switchButton)
    local effectMgr = EffectSdk.castEffectManager(this:getEffectManager())
    if (effectMgr) then
        effectMgr:setDuetMode(1)
    end
    if (effectMgr) then
        if (switchButton == 0.0) then
            effectMgr:setDuetTouchTransform(EffectSdk.Mat3(2,0,0,0,2,-0.5,0,0,1))
        else
            effectMgr:setDuetTouchTransform(EffectSdk.Mat3(2,0,-1,0,2,-0.5,0,0,1))
        end
    end
end

local GESetUniformFloat = function(this, path, GEname, uniformName, value)
    local feature = this:getFeature(path)
    local status = false
    if (feature) then
        local GEEffect = EffectSdk.castGeneralEffectFeature(feature)
        -- GEEffect:setIntensity(name, value) --set float uniform nomatter in frag or vertex shader
        status = GEEffect:setUniformFloat(GEname, 3, uniformName, value)
    end
    return status
end

local geName = "GESticker_surface2"
local UPDOWN = "surface_layout_leftright_20200329_ge"
local touchBeginX = 0.0
local touchBeginY = 0.0
local baseUpOff = 0.0
local baseDownOff = 0.0

local function setBrcData(generalEffec, effectName)
    local uv = {
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        1.0,
        1.0,
        1.0
    }
    local index = {
        0,
        1,
        2,
        1,
        3,
        2
    }
    local mode = 4
    local vertexStep = 3
    local uvStep = 2
    local vertexList = EffectSdk.getFitVertexCoord(EffectSdk.Vec2(4032, 3024), EffectSdk.Vec2(720, 1280), 0)

    -- local vertexList = EffectSdk.vectorp3()
    local uvList = EffectSdk.vectorp3()
    local indexList = EffectSdk.vectori()
    for i = 1, #uv, 2 do
        local pt = EffectSdk.Vec3(uv[i], uv[i + 1], 0)
        uvList:push_back(pt)
    end
    for i = 1, #index, 1 do
        indexList:push_back(index[i])
    end
    generalEffec:setBrcData(effectName, mode, vertexList, vertexStep, uvList, uvStep, indexList)
end

local upCornerVertex = {-1.0, -1.0, 0, 1}
-- local midCornerVertex = {-1, -0.333, 1.0, 0.333}
local downCornerVertex = {0, -1, 1.0, 1.0}

local upCornerUV = {0.0, 0.0, 1, 1}
-- local midCornerUV = {0.0, 0.3333, 1.0, 0.666}
local downCornerUV = {0.0, 0.0, 1.0, 1.0}

local function getLenX(tbl)
    -- body
    return tbl[3] - tbl[1]
end
local function getLenY(tbl)
    return tbl[4] - tbl[2]
end

local function moveY(corner, moves)
    -- local upCornerNew = {corner[1], corner[2] + moves, corner[3], corner[4] + moves}
    -- local middleY = (upCornerNew[2] + upCornerNew[4]) * 0.5
    -- local len = upCornerNew[4] - upCornerNew[2]
    -- if (middleY < len * 0.5) then
    --     upCornerNew[2] = 0.0
    --     upCornerNew[4] = len
    -- elseif (middleY > 1 - len * 0.5) then
    --     upCornerNew[2] = 1 - len
    --     upCornerNew[4] = 1.0
    -- end
    -- return upCornerNew
    local upCornerNew = {corner[1], corner[2], corner[3], corner[4]}
  
    return upCornerNew
end

local function getVertexFromCorner(corner, z)
    --
    -- return {
    --     corner[1], corner[2], z,
    --     corner[3], corner[2], z,
    --     corner[1], corner[4], z,
    --     corner[3], corner[4], z
    -- };
    local nTriangle = #corner / 4
    local ret = {}
    local inOff = 0
    local outOff = 0
    for i = 1, nTriangle do
        ret[outOff + 1] = corner[inOff + 1]
        ret[outOff + 2] = corner[inOff + 2]
        ret[outOff + 3] = z
        ret[outOff + 4] = corner[inOff + 3]
        ret[outOff + 5] = corner[inOff + 2]
        ret[outOff + 6] = z

        ret[outOff + 7] = corner[inOff + 1]
        ret[outOff + 8] = corner[inOff + 4]
        ret[outOff + 9] = z
        ret[outOff + 10] = corner[inOff + 3]
        ret[outOff + 11] = corner[inOff + 4]
        ret[outOff + 12] = z

        outOff = outOff + 12
        inOff = inOff + 4
    end
    return ret
end
local function getUVFromCorner(corner)
    --
    -- return {
    --     corner[1], corner[2],
    --     corner[3], corner[2],
    --     corner[1], corner[4],
    --     corner[3], corner[4]
    -- };
    local nTriangle = #corner / 4
    local ret = {}
    local inOff = 0
    local outOff = 0
    for i = 1, nTriangle do
        ret[outOff + 1] = corner[inOff + 1]
        ret[outOff + 2] = corner[inOff + 2]
        ret[outOff + 3] = corner[inOff + 3]
        ret[outOff + 4] = corner[inOff + 2]
        ret[outOff + 5] = corner[inOff + 1]
        ret[outOff + 6] = corner[inOff + 4]
        ret[outOff + 7] = corner[inOff + 3]
        ret[outOff + 8] = corner[inOff + 4]
        inOff = inOff + 4
        outOff = outOff + 8
    end
    return ret
end

local function getBlackHole(b, s)
    --b1b2
    --       s1s2
    --                  s3s4
    --                          b3b4
    -- print("getBlackHole: " .. b[1] .. " " .. b[2] .. " " .. b[3] .. " " .. b[4])
    -- print("getBlackHole: " .. s[1] .. " " .. s[2] .. " " .. s[3] .. " " .. s[4])

    return {
        b[1],
        b[2],
        s[1],
        b[4],
        s[1],
        b[2],
        s[3],
        s[2],
        s[1],
        s[4],
        s[3],
        b[4],
        s[3],
        b[2],
        b[3],
        b[4]
    }
end
local switchButton = 0.0
local ddyStore = 0.0

local indexbase = {
    0,
    1,
    2,
    1,
    3,
    2
}
local function setBrcDataSplit(this, path, effectName, vertex, uv)
    local feature = this:getFeature(path)
    local status = false
    if (feature == nil) then
        return false
    end
    local generalEffec = EffectSdk.castGeneralEffectFeature(feature)
    if (generalEffec == nil) then
        return false
    end

    -- local uv = {
    --     0.0, 0.0,
    --     1.0, 0.0,
    --     0.0, 1.0,
    --     1.0, 1.0,

    --     0.0, 0.0,
    --     1.0, 0.0,
    --     0.0, 1.0,
    --     1.0, 1.0

    --   }

    -- for i=1,#uv do
    --     print(uv[i]..',')
    -- end

    -- for i=1,#vertex do
    --     print(vertex[i]..',')

    -- end
    -- split 3 screen
    local index = {}
    -- calc index begin
    local indexN = #vertex / 12
    for j = 0, indexN - 1 do
        for i = 1, 6 do
            index[j * 6 + i] = indexbase[i] + 4 * j
        end
    end

    -- calc index end

    local mode = 4
    local vertexStep = 3
    local uvStep = 2
    local vertexList = EffectSdk.vectorp3()
    -- EffectSdk.LOG_LEVEL(8, "==== debug vertex ")

    for i = 1, #vertex, 3 do
        if i == 3 then
            local pt = EffectSdk.Vec3(vertex[i], vertex[i + 1], vertex[i + 2])
            vertexList:push_back(pt)
            -- EffectSdk.LOG_LEVEL(8, vertex[i] .. "," .. vertex[i + 1] .. "," .. vertex[i + 2] .. ",")
        else
            local pt = EffectSdk.Vec3(vertex[i], vertex[i + 1], vertex[i + 2])
            vertexList:push_back(pt)
            -- EffectSdk.LOG_LEVEL(8, vertex[i] .. "," .. vertex[i + 1] .. "," .. vertex[i + 2] .. ",")
        end
    end
    -- local vertexList = EffectSdk.vectorp3()
    local uvList = EffectSdk.vectorp3()
    local indexList = EffectSdk.vectori()
    -- EffectSdk.LOG_LEVEL(8, "==== debug uv ")
    for i = 1, #uv, 2 do
        local pt = EffectSdk.Vec3(uv[i], uv[i + 1], 0)
        uvList:push_back(pt)
        -- EffectSdk.LOG_LEVEL(8, uv[i] .. "," .. uv[i + 1] .. ",")
    end
    for i = 1, #index, 1 do
        indexList:push_back(index[i])
    end
    generalEffec:setBrcData(effectName, mode, vertexList, vertexStep, uvList, uvStep, indexList)
end
local function checkInBox(corner, point)
    local ret = false
    if (point[1] >= corner[1] and point[1] <= corner[3] and point[2] >= corner[2] and point[2] <= corner[4]) then
        ret = true
    end
    -- print("debug= corner" .. point[1] .. "," .. point[2] .. "," .. tostring(ret))
    return ret
end
local function getFitCoord(wid, hei, canvas_wid, canvas_hei, mode, restrict_wid, restrict_hei)
    local vertex = EffectSdk.getFitVertexCoord(EffectSdk.Vec2(wid, hei), EffectSdk.Vec2(canvas_wid, canvas_hei), mode)
    local x = -vertex[0].x / 2
    local y = -vertex[0].y
    -- print("debug getFitCoord: x= "..x.." y = "..y.." restrict_wid = "..restrict_wid.." restrict_hei = "..restrict_hei)
    -- -- return new corner & new uv
    local uv_wid = restrict_wid / x
    local uv_hei = restrict_hei / y
    local uv = {}
    local vertex = {}
    local vertex_black = {}
    -- print(
    --     "getFitCoord:x= " .. x .. " y= " .. y .. " restrict_wid = " .. restrict_wid .. " restrict_hei= " .. restrict_hei
    -- )
    -- print("getFitCoord:uv_wid = " .. uv_wid .. " uv_hei= " .. uv_hei)
    if (uv_wid > 1.0 or uv_hei > 1.0) then
        uv = {0, 0, 1, 1}
        vertex = {restrict_wid - x, restrict_hei - y, restrict_wid + x, restrict_hei + y}
        vertex_black =
            getBlackHole(
            {0, 0, restrict_wid * 2, restrict_hei * 2},
            {restrict_wid - x, restrict_hei - y, restrict_wid + x, restrict_hei + y}
        )
    else
        uv = {0.5 - uv_wid/2, 0.5 - uv_hei/2, 0.5 + uv_wid/2, 0.5 + uv_hei/2}
        vertex = {}
        vertex_black = {}
    end
    return uv, vertex, vertex_black
end
local function moveVert(corner, ox, oy)
    local new_corner = {}
    for i = 1, #corner, 2 do
        new_corner[i] = corner[i] + ox
        new_corner[i + 1] = corner[i + 1] + oy
    end
    return new_corner
    --return {corner[1] + ox, corner[2] + oy, corner[3] + ox, corner[4] + oy}
end
local function appendBlackTriangle(vertTo, uvTo, corner)
    if (#corner == 0) then
        return {}, {}
    end
    local nTriangle = #corner / 4
    local vertFrom = getVertexFromCorner(corner, 3.0)
    local nVert = #vertTo
    for i = 1, #vertFrom do
        vertTo[nVert + i] = vertFrom[i]
    end
    local nUv = #uvTo
    for i = 1, nTriangle * 8 do
        uvTo[nUv + i] = 0.0
    end
    return vertTo, uvTo
end
local getRenderCacheWidHei = function(this, key)
    local effectMgr = EffectSdk.castEffectManager(this:getEffectManager())
    local texRect = effectMgr:getRenderCacheSize(key)
    local texWidth = texRect.right
    local texHeight = texRect.bottom
    return texWidth, texHeight
end

local doNewDraw = function(this, ddy, switchButton)
    -- print("debug area begin =============")
    remapTouchXY(this, switchButton)

    local extWid, extHei = getRenderCacheWidHei(this, texKey)

    local corner_uv, vert_newpos, black_corner_vert = getFitCoord(extWid, extHei, srcWidth, srcHeight, 0, 0.5, 1)
    -- EffectSdk.LOG_LEVEL(
    --     8,
    --     "debug: handleManipulateEvent " ..
    --         " extWid= " .. extWid .. " extHei= " .. extHei .. " srcWidth= " .. srcWidth .. " srcHeight= " .. srcHeight
    -- )

    -- for i=1,#corner_vert do
    --     print(corner_vert[i]..',')
    -- end
    -- for i = 1, #corner_uv do
    --     print(corner_uv[i] .. ",")
    -- end
    -- upCornerVertex = moveVert(corner_vert, -1, -1)
    -- if (switchButton == 1) then
    --   upCornerUV = corner_uv
    -- else
    -- -- downCornerVertex = moveVert(corner_vert, -1, 0.333)
    --     downCornerUV = corner_uv
    -- end
    -- print("debug area end =============")

    local upVertex = getVertexFromCorner(upCornerVertex, switchButton)
    local downVertex = getVertexFromCorner(downCornerVertex, 1.0 - switchButton)

    -- print("vert_newpos size = " .. #vert_newpos)
    if (vert_newpos and #vert_newpos > 0) then
        if (switchButton == 1) then
        upVertex = getVertexFromCorner(moveVert(vert_newpos, upCornerVertex[1], upCornerVertex[2]), switchButton)
        else
        downVertex =
            getVertexFromCorner(moveVert(vert_newpos, downCornerVertex[1], downCornerVertex[2]), 1.0 - switchButton)
        end
    end
    -- local midVertex = getVertexFromCorner(midCornerVertex, switchButton)

    -- local midUV = getUVFromCorner(moveY(midCornerUV, 0.0))
    local upCornerUV_  --= {upCornerUV[1], upCornerUV[2], upCornerUV[3], upCornerUV[4]}
    local downCornerUV_ --= {downCornerUV[1], downCornerUV[2], downCornerUV[3], downCornerUV[4]}
    if (switchButton == 1) then
        upCornerUV_ = corner_uv
        downCornerUV_ =  {downCornerUV[1], downCornerUV[2], downCornerUV[3], downCornerUV[4]}
    else
        -- downCornerVertex = moveVert(corner_vert, -1, 0.333)
        downCornerUV_ = corner_uv
        upCornerUV_ = {downCornerUV[1], downCornerUV[2], downCornerUV[3], downCornerUV[4]}
    end

    local upUV = getUVFromCorner(moveY(upCornerUV_, 0.0))
    local downUV = getUVFromCorner(moveY(downCornerUV_, 0.0))

    local vertex = {}
    local uv = {}
    for i = 1, #upVertex do
        vertex[i] = upVertex[i]
        -- vertex[#upVertex+i]=midVertex[i]
        vertex[#upVertex + i] = downVertex[i]
    end
    for i = 1, #upUV do
        uv[i] = upUV[i]
        -- uv[#upUV+i]=midUV[i]
        uv[#upUV + i] = downUV[i]
    end
    if (black_corner_vert and #black_corner_vert > 0) then
        if (switchButton == 1) then
            vertex, uv = appendBlackTriangle(vertex, uv, moveVert(black_corner_vert, upCornerVertex[1], upCornerVertex[2]))
        else
            vertex, uv =
            appendBlackTriangle(vertex, uv, moveVert(black_corner_vert, downCornerVertex[1], downCornerVertex[2]))
        end
    end
    setBrcDataSplit(this, geName, UPDOWN, vertex, uv)
end

local maskFlag = 1.0 

EventHandles = {
    onDestroy = function(this)
        local effectManager = EffectSdk.castEffectManager(this:getEffectManager())
        if (effectManager) then
         effectManager:setDuetMode(0)
        --  EffectSdk.LOG_LEVEL(8, "debug: onDestroy called")
         local forbidList = EffectSdk.vectorv4()
         effectManager:setDuetStickerForbid(forbidList)
         effectManager:setDuetTouchTransform(EffectSdk.Mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0))

        end

    end,
    handleEffectEvent = function(this, eventCode)
        -- EffectSdk.LOG_LEVEL(8, "debug: handleEffectEvent " .. eventCode)

        if (eventCode == 1 and init_state == 1) then
            init_state = 0
            baseUpOff = 0.0
            baseDownOff = 0.0
            -- switchButton = 0.0
        end
        return true
    end,
    handleManipulateEventDuet = function(this, eventCode, x, y, dx, dy)
        -- BEF_TOUCH_BEGAN = 0,
        -- BEF_TOUCH_MOVED = 1,
        -- BEF_TOUCH_ENDED = 2,
        -- BEF_TOUCH_CANCELLED = 3,
        -- BEF_PAN = 4,
        -- BEF_ROTATE = 5,
        -- BEF_SCALE = 6,
        -- BEF_LONG_PRESS = 7"
        -- body
        if (eventCode == 0) then
            touchBeginX = x
            touchBeginY = y
        end
        -- EffectSdk.LOG_LEVEL(
        --     8,
        --     "debug: handleManipulateEvent " .. eventCode .. " x " .. x .. " y " .. y .. " dx " .. dx .. " dy " .. dy
        -- )

        -- print("eventCode " .. eventCode .. " x " .. x .. " y " .. y .. " dx " .. dx .. " dy " .. dy)
        if (eventCode == 4) then
            local ddx = x - touchBeginX
            local ddy = y - touchBeginY
            ddyStore = ddy

            GESetUniformFloat(this, geName, UPDOWN, "touch_y", y)
            GESetUniformFloat(this, geName, UPDOWN, "touch_dy", 0.0)

            -- switchButton = 0.0
            if ((switchButton == 1 and checkInBox(upCornerVertex, {x * 2 - 1, y * 2 - 1})) or (switchButton == 0 and checkInBox(downCornerVertex, {x * 2 - 1, y * 2 - 1}))) then
                doNewDraw(this, ddyStore, switchButton)
            end
        end
    end,
    handleComposerUpdateNodeEvent = function(this, path, tag, value)
        --  TODO:
        if tag == "switchButton" then
            switchButton = value
            doNewDraw(this, ddyStore, switchButton)
        end
    end,
    handleBeforeRender = function(this, timestamp)
        -- change Viewport beforeRender
        -- print("== debug stage 0")

        local effectMgr = EffectSdk.castEffectManager(this:getEffectManager())
        if (effectMgr == nil) then
            return
        end
        local duetWid = effectMgr:getDuetWidth()
        local duetHei = effectMgr:getDuetHeight()
        -- print("== debug stage 1")
        -- print("== debug duetWid = " .. duetWid .. " duetHei = " .. duetHei)

        local renderMgr = EffectSdk.castRenderManager(effectMgr:getRenderManager())
        if (renderMgr == nil) then
            return false
        end
        -- print("== debug stage 2")

        local terminalFilter = (renderMgr:getTerminalFeature()):getRenderProtocol()
        if (terminalFilter == nil) then
            return false
        end
        -- print("== debug stage 3")

        local vp = EffectSdk.Viewport(0, 0, duetWid, duetHei)

        local splitFeature = this:getFeature(geName)
        if (splitFeature == nil) then
            return false
        end
        (splitFeature:getRenderProtocol()):setViewport(vp)
        terminalFilter:setViewport(vp)
        -- print("== debug stage 4")

        doNewDraw(this, ddyStore, switchButton)

        return true
    end,
    handleRecodeVedioEvent = function(this, eventCode)
        if eventCode == 1 then
            maskFlag = 0.0

        end
        if eventCode == 2 then
            maskFlag = 1.0
        end
        GESetUniformFloat(this, geName, UPDOWN, "maskFlag", maskFlag)

        return true
    end,
    handleDisplayMetricEvent = function(this, wid, hei)
        srcWidth = wid
        srcHeight = hei
    end
}
