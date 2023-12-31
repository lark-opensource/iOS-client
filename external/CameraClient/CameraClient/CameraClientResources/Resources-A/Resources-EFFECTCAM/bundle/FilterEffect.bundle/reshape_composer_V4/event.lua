local val = {
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
}

local organParam = 
{
    0.12, -- fareye 1
    0.2, -- zoomeye 2
    0, -- rotateeye 3
    0, -- moveye 4
    -0.06, -- zoomnose 5
    -0, -- movnose 6
    -0.07, -- movmouth 7
    -0.0, -- zoommouth 8
    -0, -- movchin 9
    0.0, -- zoomforehead 10
    -0.2, -- zoomface 11
    -0.2, -- cutface 12
    -0.06, -- smallface 13
    0, -- zoomjawbone 14
    -0.04, -- zoomcheekbone 15
    0, -- fdraglips 16
    0, -- cornereye 17
    0, -- lipenhance 18
    -0.4, -- pointychin 19
    -0, -- shrinkchin 20
    2
}

local organName = {
    "DISTORTION_FACEU_FAR_EYE",
    "DISTORTION_FACEU_ZOOM_EYE",
    "DISTORTION_FACEU_ROTATE_EYE",
    "DISTORTION_FACEU_MOVE_EYE",
    "DISTORTION_FACEU_ZOOM_NOSE",
    "DISTORTION_FACEU_MOVE_NOSE",
    "DISTORTION_FACEU_MOVE_MOUTH",
    "DISTORTION_FACEU_ZOOM_MOUTH",
    "DISTORTION_FACEU_MOVE_CHIN",
    "DISTORTION_FACEU_ZOOM_FOREHEAD",
    "DISTORTION_FACEU_ZOOM_FACE",
    "DISTORTION_FACEU_CUT_FACE",
    "DISTORTION_FACEU_SMALL_FACE",
    "DISTORTION_FACEU_ZOOM_JAW_BONE",
    "DISTORTION_FACEU_ZOOM_CHEEK_BONE",
    "DISTORTION_FACEU_DRAG_LIPS",
    "DISTORTION_FACEU_CORNER_EYE",
    "DISTORTION_FACEU_LIP_ENHANCE",
    "DISTORTION_FACEU_POINTY_CHIN",
    "DISTORTION_FACEU_SHRINK_CHIN"
}

local faceVal = 0.0
local eyeVal = 0.0


EventHandles = 
{
    handleComposerUpdateNodeEvent = function (this, path, tag, percentage)
        local feature = this:getFeature("distortionFaceu_test")
        if not feature then
            EffectSdk.LOG_LEVEL(5,"lua: distortionFaceu_test feature nil")
            return false
        end

        feature:setIntensity("DISTORTION_FACEU_ALL", 1.0)
        if tag == "Face_ALL" then
            faceVal = percentage
        elseif tag == "Eye_ALL" then
            eyeVal = percentage
        end

        feature:setIntensity(organName[1], organParam[1] * faceVal)
        feature:setIntensity(organName[5], organParam[5] * faceVal)
        feature:setIntensity(organName[7], organParam[7] * faceVal)
        feature:setIntensity(organName[11], organParam[11] *faceVal)
        feature:setIntensity(organName[12], organParam[12] *faceVal )
        feature:setIntensity(organName[13], organParam[13] * faceVal )
        feature:setIntensity(organName[15], organParam[15] * faceVal)
        feature:setIntensity(organName[19], organParam[19] * faceVal)

        feature:setIntensity(organName[2], organParam[2] *  eyeVal )
        

        
       


        local effectInterface = this:getEffectManager()
        local effectManager = EffectSdk.castEffectManager(effectInterface)

        if math.abs(faceVal) == 0.0  and math.abs(eyeVal) == 0.0 then
            feature:setFeatureStatus(EffectSdk.BEF_FEATURE_STATUS_ENABLED, false)
            if effectInterface and effectManager then
                effectManager:setFeatureAlgorithmPairs(feature:getAbsPath(), EffectSdk.BefRequirement())
            end
        else
            feature:setFeatureStatus(EffectSdk.BEF_FEATURE_STATUS_ENABLED, true)
            if effectInterface and effectManager then
                effectManager:setFeatureAlgorithmPairs(feature:getAbsPath(), feature:getRequirement())
            end
        end

        return true
    end
}