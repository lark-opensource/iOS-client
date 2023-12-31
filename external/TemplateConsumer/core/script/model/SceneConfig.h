//
// Created by bytedance on 2021/5/23.
//

#ifndef SCRIPTMODEL_SCENECONFIG_H
#define SCRIPTMODEL_SCENECONFIG_H


#ifdef __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLENode.h>
#include <NLEPlatform/NLENodeDecoder.h>
#include <NLEPlatform/NLESequenceNode.h>
#include <NLEPlatform/NLEFeature.h>
#else
#include <NLENode.h>
#include <NLENodeDecoder.h>
#include <NLESequenceNode.h>
#include <NLEFeature.h>
#endif

#include <vector>
#include <string>
#include <memory>

#include "SceneType.h"
#include "SceneConfig.h"


using cut::model::NLENode;
using cut::model::NLEFeature;
using cut::model::NLETimeSpaceNode;
using cut::model::NLENodeDecoder;
using cut::model::NLEValueProperty;
using cut::model::NLEObjectListProperty;

namespace script::model {


    /**
     * 针对场景的一些配置
     */
    class NLE_EXPORT_CLASS SceneConfig : public cut::model::NLETimeSpaceNode {
    NLENODE_RTTI(SceneConfig)

    KEY_FUNCTION_DEC_OVERRIDE(SceneConfig)
    /**
     * 这场景的类型 是否支持卡点
     */
    NLE_PROPERTY_DEC(SceneConfig, SceneType, SceneType, SceneType::SCENE_COMMON ,NLEFeature::E)

    /**
     * 卡点类型 需要知道每段长度
     */
    NLE_PROPERTY_DEC(SceneConfig, ClipTimes, std::vector<int64_t>, std::vector<int64_t>(), NLEFeature::E )


    public:
        SceneConfig();
        virtual ~SceneConfig();


    private:



    public:



    };



}
#endif //SCRIPTMODEL_SCENECONFIG_H
