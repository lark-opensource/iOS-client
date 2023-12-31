//
// Created by bytedance on 3/25/21.
//


#ifndef TEMPLATECONSUMER_SCRIPT_CONSUMER_H
#define TEMPLATECONSUMER_SCRIPT_CONSUMER_H

#ifdef __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLESequenceNode.h>
#else
#include <NLESequenceNode.h>
#endif


#include <memory>
#include <string>
#include <map>
#include "model/ScriptScene.h"
#include "model/ScriptModel.h"


using cut::model::NLEModel;
using cut::model::NLETrack;
using script::model::ScriptModel;

namespace script::model {
    static int CONVERT_FAIL = -1;
    static int CONVERT_SUCCESS = 0;


    class NLE_EXPORT_CLASS ScriptConsumerListener {
    public:
        ScriptConsumerListener() = default;

        virtual ~ScriptConsumerListener() = default;

        virtual void onAdjustSlot(std::shared_ptr<cut::model::NLETrackSlot> slot, cut::model::NLEResType type) = 0;

        virtual void onSortSlotInScene(std::shared_ptr<cut::model::NLETrackSlot> preSlot, int index,
                                       std::shared_ptr<cut::model::NLETrackSlot> curSlot) = 0;
    };

    class ScriptConsumer {
    private:
        std::map<cut::model::NLETrackType, int32_t> typeToLayer;

        int sceneTempIndex;

        void addTrackToNLE(std::shared_ptr<NLEModel> &sharedPtr,
                           std::shared_ptr<NLETrack> &track,
                           cut::model::NLETrackType type,
                           int64_t endTime,
                           int64_t curMaxTime);

        void addAudioTrackToNLE(std::shared_ptr<cut::model::NLEModel> &nleModel,
                                std::shared_ptr<cut::model::NLETrack> &track,
                                std::shared_ptr<cut::model::NLETrack> &preTrack,
                                int64_t preSceneTime,
                                int64_t curMaxTime);

        void addGobalTrackToNLE(std::shared_ptr<script::model::ScriptModel> &scriptModel,
                                std::shared_ptr<cut::model::NLEModel> &nleModel);

        void removeAllDefaultMutableSlot(std::shared_ptr<script::model::ScriptModel> &scriptModel);

        void addSceneToNLEModel(std::shared_ptr<ScriptScene> &preScene,
                                std::shared_ptr<ScriptScene> &scene,
                                std::shared_ptr<ScriptScene> &nextScene,
                                std::shared_ptr<cut::model::NLEModel> nleModel);

        void adjustScene(std::shared_ptr<ScriptScene> &preScene,
                         std::shared_ptr<ScriptScene> &scene,
                         std::shared_ptr<ScriptScene> &nextScene);

        void adjustSceneResouce(std::shared_ptr<ScriptScene> &scene);

        void addMainTrackToNLE(std::shared_ptr<script::model::ScriptScene> scene,
                               std::shared_ptr<cut::model::NLETrack> mainTrack,
                               std::shared_ptr<cut::model::NLEModel> nleModel);

        int32_t  getNiceLayer(cut::model::NLETrackType type, int32_t targLayer);

    public:

        // 给NLEModel添加 脚本模版
        int32_t addScriptModel(std::shared_ptr<NLEModel> &nModel,
                               std::shared_ptr<ScriptModel> &scriptModel);


        std::shared_ptr<script::model::ScriptConsumerListener> listener;


    };


}

#endif //TEMPLATECONSUMER_SCRIPT_CONSUMER_H
