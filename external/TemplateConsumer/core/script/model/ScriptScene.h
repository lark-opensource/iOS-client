//
// Created by bytedance on 2021/5/23.
//
#include <vector>
#include <string>
#include <memory>
#include "SMutableMaterial.h"
#include "SceneConfig.h"

#ifdef __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLESequenceNode.h>
#else
#include <NLESequenceNode.h>
#endif

#ifndef SCRIPTMODEL_SCRIPTSCENE_H
#define SCRIPTMODEL_SCRIPTSCENE_H


using cut::model::NLEFeature;
using cut::model::NLETimeSpaceNode;
using cut::model::NLETrack;
using cut::model::NLEObjectProperty;
using cut::model::NLESegmentTransition;
using script::model::SceneConfig;
using script::model::SMutableMaterial;

namespace script::model {

    /**
     * 模板的场景信息
     */
    class NLE_EXPORT_CLASS ScriptScene :public cut::model::NLEModel{
    NLENODE_RTTI(ScriptScene);
    KEY_FUNCTION_DEC_OVERRIDE(ScriptScene)

    /**
     * 场景展示tab的名字
     */
    NLE_PROPERTY_DEC(ScriptScene,SceneTabName,std::string,"",NLEFeature::E)
    /**
     * 场景索引
     */
    NLE_PROPERTY_DEC(ScriptScene,SceneIndex,int32_t ,0,NLEFeature::E)
    /**
     * 场景描述名字
     */
    NLE_PROPERTY_DEC(ScriptScene,SceneName,std::string,"",NLEFeature::E)
    /**
     * 场景的封面
     */
    NLE_PROPERTY_DEC(ScriptScene, CoverUrl, std::string, "", NLEFeature::E)
    /**
     * 场景ID
     */
    NLE_PROPERTY_DEC(ScriptScene, SceneId, std::string, "", NLEFeature::E)

    /**
     * 场景的示例视频信息
     */
    NLE_PROPERTY_DEC(ScriptScene, VideoInfo, std::string, "", NLEFeature::E)
    /**
     * 场景的描述
     */
    NLE_PROPERTY_DEC(ScriptScene, Desc, std::string, "", NLEFeature::E)

    /**
     * 场景的建议介绍
     */
    NLE_PROPERTY_DEC(ScriptScene, SuggestDesc, std::string, "", NLEFeature::E)

    /**
     * 场景的一些配置信息 如是否支持卡点
     */
    NLE_PROPERTY_OBJECT(ScriptScene, SceneConfig, SceneConfig, NLEFeature::E)
    /**
     * 场景片头后转场
     */
    NLE_PROPERTY_OBJECT(ScriptScene,FrontTransition,NLESegmentTransition,NLEFeature::E)
    /**
     * 场景片尾前转场
     */
    NLE_PROPERTY_OBJECT(ScriptScene,BackTransition,NLESegmentTransition,NLEFeature::E)
    /**
     * 场景片尾后转场
     */
    NLE_PROPERTY_OBJECT(ScriptScene,BackEndTransition,NLESegmentTransition,NLEFeature::E)

    public:
        ScriptScene();

        virtual ~ScriptScene();

    private:







    public:
        std::shared_ptr<NLETrack> findMainTrack();
        int64_t getSceneMaxEnd();
        int64_t getSceneMinStart();
        virtual void addMaterials(const std::vector<std::shared_ptr<SMutableMaterial>> &childs);

        virtual void removeMaterials(const std::vector<std::shared_ptr<SMutableMaterial>> &childs);

        virtual void addMaterial(const std::shared_ptr<SMutableMaterial> &child);

        virtual bool removeMaterial(const std::shared_ptr<SMutableMaterial> &child) ;
        virtual void clearMaterial() ;
        virtual std::vector<std::shared_ptr<SMutableMaterial>> getMaterials() const;




        };
}

#endif //SCRIPTMODEL_SCRIPTMODEL_H
