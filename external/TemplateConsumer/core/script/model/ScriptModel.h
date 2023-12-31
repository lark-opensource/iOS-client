//
// Created by bytedance on 2021/5/23.
//


#ifndef SCRIPTMODEL_SCRIPTMODEL_H
#define SCRIPTMODEL_SCRIPTMODEL_H

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

#include <vector>
#include <string>
#include <map>
#include <memory>
#include <iomanip>
#include "ScriptScene.h"
#include "ScriptModelConfig.h"

using cut::model::NLENode;
using cut::model::NLETimeSpaceNode;
using cut::model::NLENodeDecoder;
using cut::model::NLEValueProperty;
using cut::model::NLEObjectListProperty;

namespace script::model {


    /**
     * 模板的脚本数据模型
     */
   class NLE_EXPORT_CLASS ScriptModel: public NLETimeSpaceNode  {
   NLENODE_RTTI(ScriptModel);
   KEY_FUNCTION_DEC_OVERRIDE(ScriptModel)
   /**
    * 模板
    */
   NLE_PROPERTY_DEC(ScriptModel, Title, std::string, "", NLEFeature::E)
   /**
    * 模板封面
    */
   NLE_PROPERTY_DEC(ScriptModel, CoverUrl, std::string, "", NLEFeature::E)
   /**
    * 模板描述
    */
   NLE_PROPERTY_DEC(ScriptModel, Desc, std::string, "", NLEFeature::E)

   /**
    * 模板配置参数
    */
   NLE_PROPERTY_OBJECT(ScriptModel, Config, script::model::ScriptModelConfig  , NLEFeature::E)

       /**
        *  模板id
        */
   NLE_PROPERTY_DEC(ScriptModel, TemplateId, std::string, "", NLEFeature::E)

       /**
        * 模板下的场景信息
        */
   NLE_PROPERTY_OBJECT_LIST(ScriptModel, Scene, ScriptScene, NLEFeature::E);

   /**
    * 作用整个模板的特效
    */
   NLE_PROPERTY_OBJECT_LIST(ScriptModel, GlobalTrack, NLETrack, NLEFeature::E);



   public:
       ScriptModel();
       virtual ~ScriptModel();

   private:


   public:

       /**
        * 通过场景的ID获**取场景信息(只读)
        * @return
        */
       std::shared_ptr<ScriptScene>  get_scene_byId(std::string id) const;

       std::vector<std::shared_ptr<script::model::ScriptScene>> getSortedScene() const;

       std::string  saveDraft();

       static std::shared_ptr<ScriptModel> restore(std::string scriptStr );


       std::vector<std::shared_ptr<cut::model::NLEResourceNode>> getAllResources() ;



   };
}

#endif //SCRIPTMODEL_SCRIPTMODEL_H
