EventHandles = 
{
    handleComposerUpdateNodeEvent = function (this, path, tag, percentage)
        local feature = this:getFeature("GeneralEffect")
        if not feature then
            EffectSdk.LOG_LEVEL(5, "lua: live qingyan beauty feature nil")
            return false
        end

        if(tag == "Smooth_ALL") then
            feature:setIntensity("epm_live/frag/blurAlpha", percentage*0.85)
        end
        
        feature:setIntensity("epm_live/frag/sharpen", 0.7)


    end
}