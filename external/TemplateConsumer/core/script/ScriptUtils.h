//
// Created by bytedance on 2021/6/3.
//

#ifndef TEMPLATECONSUMERAPP_SCRIPTUTILS_H
#define TEMPLATECONSUMERAPP_SCRIPTUTILS_H

#ifdef __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLESequenceNode.h>
#else
#include <NLESequenceNode.h>
#endif

#include "AlignModelType.h"
#include "model/SMutableMaterial.h"
#include <map>

namespace cut::model {
    class NLETrackSlot;
}
namespace script::model {


    class ScriptUtils {
    private:



    public:

        /**
         * 获取slot对齐Scene的方式
         * @param slot
         * @return
         */
        static AlignModelType getAlignModel(const std::shared_ptr<cut::model::NLETrackSlot> &slot);

        /**
         * 设置对齐的方式
         * @param slot
         * @param alignModelType
         */
        static void setAlignModel(std::shared_ptr<cut::model::NLETrackSlot> &slot, AlignModelType alignModelType);


        /**
         * 是否在和场景start对齐
         * @param slot
         * @return
         */
        static int64_t getAlignPaddingStart(std::shared_ptr<cut::model::NLETrackSlot> &slot);

        static void setAlignPaddingStart(std::shared_ptr<cut::model::NLETrackSlot> &slot, int64_t paddingStart);

        static int64_t getAlignPaddingEnd(std::shared_ptr<cut::model::NLETrackSlot> &slot);


        /**
         * 设置距离场景结束的时间
         * @param slot
         * @param paddingStart
         */
        static void setAlignPaddingEnd(std::shared_ptr<cut::model::NLETrackSlot> &slot, int64_t paddingStart);


        /**
         *
         * @param slot
         * @param paddingStart
         */
        static void setAlignPadding(std::shared_ptr<cut::model::NLETrackSlot> &slot, int64_t paddingStart, int64_t paddingEnd);

        /**
         * 设置当前的slot是片头 （主轨）
         * @param slot
         */
        static void setClipAtHead(std::shared_ptr<cut::model::NLETrackSlot> &slot);
        /**
         * 设置当前slot为片尾(主轨)
         * @param slot
         */
        static void setClipAtTail(std::shared_ptr<cut::model::NLETrackSlot> &slot);

        static bool isClipAtTail(std::shared_ptr<cut::model::NLETrackSlot> &slot);

        static bool isClipAtHead(std::shared_ptr<cut::model::NLETrackSlot> &slot);

        static int64_t msToUs(int64_t ms);

        static int64_t usToMs(int64_t ms) ;

        static bool  isMutableResNode(std::shared_ptr<cut::model::NLEResourceNode> &node);

        static bool  isMutableNLESlot(std::shared_ptr<cut::model::NLETrackSlot> &node);

        static std::vector<std::shared_ptr<cut::model::NLESegment>> getAllNLESegments(
                std::shared_ptr<cut::model::NLEModel> nleModel);

        static std::vector<std::shared_ptr<cut::model::NLESegment>> getNLESegmentsByType(
                cut::model::NLEResType type, std::shared_ptr<cut::model::NLEModel> nleModel);
        
        static void setExtraForNode(std::shared_ptr<cut::model::NLEResourceNode> &node,std::string key, std::string value);

        static void setExtraForSlot(std::shared_ptr<cut::model::NLEResourceNode> &node,std::string key, std::string value);

        static void setExtraForSegment(std::shared_ptr<cut::model::NLEResourceNode> &node,std::string key, std::string value);

        static std::shared_ptr<cut::model::NLETrack> geneStickerTrack( std::vector<std::shared_ptr<script::model::SubTitle>> subTitles);

        static float toVeX(float nleX);
        static float toVeY(float nleY);
        static float toNleX(float veX);
        static float toNleY(float veY);

        static std::map<int,std::shared_ptr<cut::model::NLESegmentTransition>> getAllIndexTransition(
                std::shared_ptr<cut::model::NLEModel> nleModel);

        static void resetAllTransition(std::map<int,std::shared_ptr<cut::model::NLESegmentTransition>> transitions,
                                                  std::shared_ptr<cut::model::NLEModel> nleModel);

        static float canvesRatioType2Ratio(CanvasRatioType type) ;

    };

}
#endif //TEMPLATECONSUMERAPP_SCRIPTUTILS_H
