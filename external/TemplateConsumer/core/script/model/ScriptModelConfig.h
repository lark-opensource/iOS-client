//
// Created by bytedance on 2021/6/7.
//
#ifndef TEMPLATECONSUMERAPP_SCRIPTMODELCONF_H
#define TEMPLATECONSUMERAPP_SCRIPTMODELCONF_H

#ifdef __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLENodeDecoder.h>
#include <NLEPlatform/NLENode.h>
#include <NLEPlatform/NLESequenceNode.h>
#include <NLEPlatform/NLEFeature.h>
#else
#include <NLENodeDecoder.h>
#include <NLENode.h>
#include <NLESequenceNode.h>
#include <NLEFeature.h>
#endif

#include "SceneType.h"

namespace cut::model {
    class NLEFeature;
}
using cut::model::NLENode;
using cut::model::NLEResourceNode;
using cut::model::NLENodeDecoder;
using cut::model::NLEFeature;
using cut::model::NLEValueProperty;
using cut::model::NLEObjectProperty;
using cut::model::NLEObjectListProperty;

using script::model::CanvasRatioType;
/**
 * 整个ScriptModel的配置信息
 */
namespace script::model {



    class NLE_EXPORT_CLASS ScriptModelConfig : public cut::model::NLENode {

    NLENODE_RTTI(ScriptModelConfig);
    KEY_FUNCTION_DEC_OVERRIDE(ScriptModelConfig)

        /**
        * 画幅
         */
    NLE_PROPERTY_DEC(ScriptModelConfig, RatioType, CanvasRatioType, CanvasRatioType::RATIO_16_9, NLEFeature::E)

    // 配置的字幕信息
    NLE_PROPERTY_OBJECT(ScriptModelConfig, SubTitleStyle, cut::model::NLEStyText, cut::model::NLEFeature::E)


    public:
        ScriptModelConfig();

        virtual ~ScriptModelConfig();


    };

}
#endif //TEMPLATECONSUMERAPP_SCRIPTMODELCONF_H
