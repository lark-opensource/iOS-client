//
// Created by bytedance on 2021/5/31.
//

#include "ScriptConsumerConst.hpp"
#include "ScriptUtils.h"
#include "model/ScriptScene.h"
#include <fstream>
#include <iostream>
#include <string>
#include <math.h>
#include <dirent.h>
#include <algorithm>
#include<map>
#if __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLEResourceNode.h>
#include <NLEPlatform/NLESequenceNode.h>

#else
#include <NLEResourceNode.h>
#include <NLESequenceNode.h>

#endif

/**** 常量 */
#define ExtraNodeKey std::string("xigua_node_")
#define ExtraSlotKey std::string("xigua_slot_")
#define ExtraSegmentKey std::string("xigua_seg_")
#define MUTABLE_MAX_TIME   0x7FFFFFFFFFFFF000

using cut::model::NLESegment;
using cut::model::NLESegmentAudio;
using cut::model::NLETrackSlot;
using cut::model::NLESegmentTextSticker;
using cut::model::NLEResourceNode;
using script::model::ScriptScene;
using namespace script::model;

static cut::model::NLETrackType getTrackType(std::shared_ptr<NLETrack> track) ;
static void addExtraForXNode(std::shared_ptr<cut::model::NLETrackSlot> &slot);

static void tagNLENodeScript(std::shared_ptr<NLENode> &nleNode) {
    if (nleNode != nullptr) {
        nleNode->setExtra(EXTRA_KEY_BUSINESS, EXTRA_VAL_SCRIPT);

    }
}

static float canvesRatioTypeToRatio(CanvasRatioType type) {
    float help_float = static_cast<float>(1);
    float  canvasRatio = 16 * help_float  / 9;
    switch (type) {
        case  CanvasRatioType::RATIO_16_9 :  canvasRatio = 16 * help_float  / 9; break;
        case  CanvasRatioType::RATIO_1_1 :  canvasRatio =   help_float ; break;
        case  CanvasRatioType::RATIO_3_4 :  canvasRatio = 3 * help_float  / 4; break;
        case  CanvasRatioType::RATIO_4_3 :  canvasRatio = 4 * help_float  / 3; break;
        case  CanvasRatioType::RATIO_9_16 :  canvasRatio = 9 * help_float  / 16; break;
    }
    return canvasRatio;
}

static std::shared_ptr<cut::model::NLEResourceNode> createNLEResourceNode(cut::model::NLEResType type,
                                                       const std::string &file,
                                                       const std::string &resId,
                                                       const std::string &resName,
                                                       const bool  isAmazing) {
    auto res = std::make_shared<cut::model::NLEResourceNode>();
    if (isAmazing) {
        res->setResourceTag(cut::model::NLEResTag::AMAZING);
    }
    res->setResourceName(resName);
    res->setResourceType(type);
    res->setResourceId(resId);
    res->setResourceFile(file);
    return res;
}

static std::shared_ptr<cut::model::NLEResourceAV> createAudioOrVideoNode(cut::model::NLEResType type,
                                                       const std::string &file,
                                                       const std::string &resName,
                                                       const bool  isAmazing) {
    auto res = std::make_shared<cut::model::NLEResourceAV>();
    res->setResourceType(type);
    res->setResourceName(resName);
    res->setResourceFile(file);
    return res;
}

static void  setDefaultMutableSlot(std::shared_ptr<NLETrackSlot> &slot) {
    slot->setExtra(EXTRA_TAG_DEFAULT_MATERIAL, "true");
}

static bool  isDefaultMutableSlot(std::shared_ptr<NLETrackSlot> slot) {
    auto materialTag = slot->getExtra(EXTRA_TAG_DEFAULT_MATERIAL);
    if (materialTag.empty() || "false" == materialTag) {
        return false;
    } else {
        return true;
    }
}

static void  setMutableVideo(std::shared_ptr<NLETrackSlot> &slot) {
    slot->setExtra(EXTRA_TAG_MATERIAL, "true");
}

static bool  hasMutableVideo(std::shared_ptr<NLETrackSlot> slot) {
    auto materialTag = slot->getExtra(EXTRA_TAG_MATERIAL);
    if (materialTag.empty() || "false" == materialTag) {
        return false;
    } else {
        return true;
    }
}
static int64_t  se2us(int32_t se) {
   return se * 1000 * 1000;
}

static void  setMutableNode(std::shared_ptr<cut::model::NLEResourceNode> node) {
    node->setExtra(EXTRA_TAG_MATERIAL, "true");
}

static bool  isMutableNode(std::shared_ptr<cut::model::NLEResourceNode> &node) {
    auto materialTag = node->getExtra(EXTRA_TAG_MATERIAL);
    if (materialTag.empty() || "false" == materialTag) {
        return false;
    } else {
        return true;
    }
}

static void removeMutableSlot(std::shared_ptr<NLETrack> track) {
    if (track->getMainTrack()) {
        for(auto &slot : track->getSlots()) {
            if (hasMutableVideo(slot)) {
                track->removeSlot(slot);
            }
        }
    }
}

static std::vector<std::shared_ptr<NLETrack>> getTracksFromScene(
        std::shared_ptr<script::model::ScriptScene> scene,
                                                                 cut::model::NLETrackType trackType) {
    std::vector<std::shared_ptr<NLETrack>> resTrack;
    for (auto &track : scene->getTracks()) {
        if (track->getTrackType() == trackType || track->getExtraTrackType() == trackType) {
            resTrack.push_back(track);
        }
    }
    return resTrack;
}

/**
 * 从NLEModel获取 layer和TrackType()都等于目标layer和TrackType的Track，若没有返回Null
 * @param nleModel
 * @param layer
 * @param trackType
 * @return
 */
static std::shared_ptr<NLETrack> findTrackByLayer(
        std::shared_ptr<cut::model::NLEModel> nleModel,
        int32_t  layer,
                                                  cut::model::NLETrackType trackType) {
    for (auto &track : nleModel->getTracks()) {
        if (
                (track->getTrackType() == trackType
            || track->getExtraTrackType() == trackType)
               && track->getLayer() == layer) {
            return track;
        }
    }
    return nullptr;
}

static std::vector<std::shared_ptr<NLETrack>> findTrackByType(
        std::shared_ptr<cut::model::NLEModel> nleModel,cut::model::NLETrackType trackType) {
    std::vector<std::shared_ptr<NLETrack>> targetTracks = std::vector<std::shared_ptr<NLETrack>>();
    for (auto &track : nleModel->getTracks()) {
        if (getTrackType(track) == trackType && !track->getMainTrack()) {
            targetTracks.push_back(track);
        }
    }
    return targetTracks;
}

static std::vector<std::shared_ptr<NLETrack>> findTrackByType(
        std::shared_ptr<script::model::ScriptScene> scene,
        cut::model::NLETrackType trackType) {
    std::vector<std::shared_ptr<NLETrack>> targetTracks = std::vector<std::shared_ptr<NLETrack>>();
    if(scene != nullptr){
        for (auto &track : scene->getTracks()) {
            if (getTrackType(track) == trackType) {
                targetTracks.push_back(track);
            }
        }
    }
    return targetTracks;
}

static cut::model::NLETrackType getTrackType(std::shared_ptr<NLETrack> track) {
    auto trackType = track->getTrackType();
    auto trackType2 = track->getExtraTrackType();
    if (trackType != cut::model::NLETrackType::NONE) {
        return trackType;
    } else if (trackType2 != cut::model::NLETrackType::NONE) {
        return trackType2;
    }
    return cut::model::NLETrackType::NONE;
}

static std::shared_ptr<cut::model::NLETrack> findMainTrack(std::shared_ptr<cut::model::NLEModel> nleModel) {
    if (nleModel != nullptr && !nleModel->getTracks().empty()) {
        for (auto &track : nleModel->getTracks()) {
            if (track->getMainTrack()) {
                return track;
            }
        }
    }

    return nullptr;
}
static std::shared_ptr<cut::model::NLETrack> findMainTrack(std::shared_ptr<ScriptScene> scene) {
    if (scene != nullptr && !scene->getTracks().empty()) {
        for (auto &track : scene->getTracks()) {
            if (track->getMainTrack()) {
                return track;
            }
        }
    }

    return nullptr;
}

/**
 * 对齐方式
 * @param slot
 * @return
 */
static std::string getAlignModelForSlot( std::shared_ptr<cut::model::NLETrackSlot> slot) {
    auto align = slot->getExtra(EXTRA_TAG_ALIGN_MODE_SCENE);
    if (align.empty()) { // 默认是固定
        return EXTRA_VAL_ALIGN_MODE_SCENE_NONE;
    }

    return align;
}


static int64_t getAligPaddingStart( std::shared_ptr<cut::model::NLETrackSlot> slot) {
    auto align = slot->getExtra(EXTRA_VAL_ALIGN_MODE_SCENE_PADDING_START);
    if (align.empty()) {
        return 0;
    }

    return  atol(align.c_str());
}

static int64_t getAligPaddingEnd( std::shared_ptr<cut::model::NLETrackSlot> slot) {
    auto align = slot->getExtra(EXTRA_VAL_ALIGN_MODE_SCENE_PADDING_END);
    if (align.empty()) {
        return 0;
    }

    return  atol(align.c_str());
}

static void handleAlignForTrack(int64_t sceneMax, const std::shared_ptr<cut::model::NLETrack> &track) {
    auto nNode = std::dynamic_pointer_cast<cut::model::NLENode>(track);
    tagNLENodeScript(nNode);
    for (auto &slot : track->getSlots()) {
        auto slotDuration = slot->getEndTime() - slot->getStartTime();
        if (getAlignModelForSlot(slot) == EXTRA_VAL_ALIGN_MODE_SCENE_LEFT) {
            auto paddingStart = getAligPaddingStart(slot);
            slot->setStartTime(paddingStart);
            auto  realEndTime = std::max(paddingStart, std::min(paddingStart + slotDuration , sceneMax));
            slot->setEndTime(realEndTime);
        } else if (getAlignModelForSlot(slot) == EXTRA_VAL_ALIGN_MODE_SCENE_RIGHT) {
            auto realEndTime = sceneMax;
            slotDuration = std::min(slotDuration, getAligPaddingStart(slot));
            auto realStartTime = std::max((int64_t) 0, realEndTime - slotDuration);
            slot->setStartTime(realStartTime);
            slot->setEndTime(realEndTime);

        } else if (getAlignModelForSlot(slot) == EXTRA_VAL_ALIGN_MODE_SCENE_BOTH) {
            auto paddingEnd = sceneMax - std::max((int64_t) 0, getAligPaddingEnd(slot));
            auto paddingStart = std::max((int64_t) 0, getAligPaddingStart(slot));
            slot->setStartTime(paddingStart);
            slot->setEndTime(paddingEnd);
        }
        if (!slot->hasEndTime() || slot->getEndTime() < 0 ) {
            slot->setEndTime(sceneMax);
        }
        if (slot->getEndTime() > sceneMax) {
            slot->setEndTime(sceneMax);
        }
        if(slot->getDuration() <= 0){
            track->removeSlot(slot);
        }
    }
}

/*
 * 音频处理逻辑,这里先处理场景内Slot的位置,后续合并和复制将会在addAudioTrackToNLE中处理
 *  1.非跨场景情况下，根据音乐场景内paddingStart和paddingEnd，计算出duration
 *  a：duration超过音乐时长就复制音乐片段实现循环播放效果，同时fadeIn只加在第一个片段，fadeOut只加在最后一个片段
 *  b：duration为负数则不添加移除音乐
 *  c：duration大于0但小于音乐时长则截断播放
    2.跨场景合并条件
    a：前一个场景中存在音乐A，并且paddingEnd为0
    b：当前场景也存在音乐A，并且paddingStart为0
 */
static void handleAlignForAudioTrack(int64_t sceneMax,const std::shared_ptr<cut::model::NLETrack> &track) {
    auto nNode = std::dynamic_pointer_cast<cut::model::NLENode>(track);
    tagNLENodeScript(nNode);
    for (auto &slot : track->getSlots()) {
        auto seg = std::dynamic_pointer_cast<cut::model::NLESegmentAudio>(slot->getMainSegment());
        if(seg != nullptr){
            auto resource = seg->getResource();
            auto slotDuration = resource->getDuration();
            if(resource  == nullptr || slotDuration == 0){
                track->removeSlot(slot);
                continue;
            }
            
            if (getAlignModelForSlot(slot) == EXTRA_VAL_ALIGN_MODE_SCENE_LEFT) {
                auto paddingStart = getAligPaddingStart(slot);
                slot->setStartTime(paddingStart);
                auto  realEndTime = std::max(paddingStart, std::min(paddingStart + slotDuration , sceneMax));
                slot->setEndTime(realEndTime);
            } else if (getAlignModelForSlot(slot) == EXTRA_VAL_ALIGN_MODE_SCENE_RIGHT) {
                auto realEndTime = sceneMax;
                slotDuration = std::min(slotDuration, getAligPaddingStart(slot));
                auto realStartTime = std::max((int64_t) 0, realEndTime - slotDuration);
                slot->setStartTime(realStartTime);
                slot->setEndTime(realEndTime);

            } else if (getAlignModelForSlot(slot) == EXTRA_VAL_ALIGN_MODE_SCENE_BOTH) {
                auto paddingEnd = sceneMax - std::max((int64_t) 0, getAligPaddingEnd(slot));
                auto paddingStart = std::max((int64_t) 0, getAligPaddingStart(slot));
                slot->setStartTime(paddingStart);
                slot->setEndTime(paddingEnd);
            }
            if (!slot->hasEndTime() || slot->getEndTime() < 0 ) {
                slot->setEndTime(sceneMax);
            }
            if (slot->getEndTime() > sceneMax) {
                slot->setEndTime(sceneMax);
            }
            
            if(slot->getDuration() <= 0){
                track->removeSlot(slot);
            }
        }else{
            track->removeSlot(slot);
            continue;
        }
    }
    track->timeSort();
}

static void handleAlignForTracks(const std::shared_ptr<ScriptScene> &scene, cut::model::NLETrackType trackType) {

    auto sceneMax = scene->getSceneMaxEnd();
    for (auto &track : getTracksFromScene(scene, trackType)) {
        handleAlignForTrack(sceneMax, track);


    }

}

static void setTrackLayer(std::shared_ptr<cut::model::NLETrack> track, int32_t layer) {
    track->setLayer(layer);
    for (auto &slot : track->getSlots()) {
        slot->setLayer(layer);
    }
}

static int64_t getVideoTrackEndMax(std::shared_ptr<cut::model::NLETrack> &track) {
    int64_t targetEnd = 0;
    if (track->getTrackType() ==cut::model:: NLETrackType::VIDEO
        || track->getExtraTrackType() == cut::model::NLETrackType::VIDEO) {
        int64_t trackEnd = track->getMaxEnd();
        if (targetEnd == -1 || trackEnd > targetEnd) {
            targetEnd = trackEnd;
        }
    }

    return targetEnd;
}
/**
 * 判断两个slot中的资源是否相同
 * @param preSlot
 * @param curSlot
 * @return
 */
static bool isSameResoure(std::shared_ptr<cut::model::NLETrackSlot> &preSlot,
                          std::shared_ptr<cut::model::NLETrackSlot> &curSlot) {
    if (preSlot && curSlot) {
        if (preSlot->getMainSegment()->getClassName() == curSlot->getMainSegment()->getClassName()) {
            // 音视频的取avFile中的元数据比较
            if (std::dynamic_pointer_cast<cut::model::NLESegmentAudio>(preSlot->getMainSegment())->getAVFile() &&
                std::dynamic_pointer_cast<cut::model::NLESegmentAudio>(curSlot->getMainSegment())->getAVFile()) {
                return std::dynamic_pointer_cast<cut::model::NLESegmentAudio>(
                        preSlot->getMainSegment())->getAVFile()->getResourceFile()
                       == std::dynamic_pointer_cast<cut::model::NLESegmentAudio>(
                        curSlot->getMainSegment())->getAVFile()->getResourceFile();

            } else if (preSlot->getMainSegment()->getResource() && curSlot->getMainSegment()->getResource()) {

                return preSlot->getMainSegment()->getResource()->getResourceFile()
                       == curSlot->getMainSegment()->getResource()->getResourceFile();
            }
        }
    }
    return false;
}

static void removeScriptForNode(const std::shared_ptr<NLENode> node) {
    for(auto key : node->getExtraKeys() ) {
        if (key.rfind("script_", 0) == 0) {
            node->setExtra(key, "");
        }
    }
}
static void removeScriptTag(const std::shared_ptr<cut::model::NLEModel> nleModel) {
    if (nleModel != nullptr) {
        for(auto &track : nleModel->getTracks()) {
            removeScriptForNode(track);

            for(auto &slot : track->getSlots()) {
                removeScriptForNode(slot);

            }
        }
    }
}


static void reCheckNLEModel(std::shared_ptr<cut::model::NLEModel> &nModel) {
    for (auto track: nModel->getTracks()) {
        // 1. 去无slot的track
        if (track->getSlots().size() == 0) {
            nModel->removeTrack(track);

        } else {
            // 2. 添加对应的Extra到对应层级
            for (auto &slot : track->getSortedSlots()) {
                addExtraForXNode(slot);
            }
        }
    }

}

static void removeEmptyResourceSlot(const std::shared_ptr<ScriptScene> &scene) {
    LOGGER->e("removeEmptyResourceSlot ---");

    for (auto &track : scene->getTracks()) {
        for(auto &slot : track->getSortedSlots()) {
            if (getTrackType(track)== cut::model::NLETrackType::VIDEO || getTrackType(track)== cut::model::NLETrackType::AUDIO) {
                
                auto segment = cut::model::NLESegmentAudio::dynamicCast(slot->getMainSegment());
                if (segment == nullptr   || segment->getAVFile() == nullptr || segment->getAVFile()->getDuration() <= 0
                    || segment->getAVFile()->getResourceFile().empty() || segment->getTimeClipStart() < 0 || segment->getTimeClipEnd() <= 0) {
                    track->removeSlot(slot);
                }
            } else {
                auto segment = slot->getMainSegment();
                if (auto sticker_segment = cut::model::NLESegmentTextSticker::dynamicCast(segment)) {
                    if (!sticker_segment->toEffectJson().empty()) {
                        continue;
                    }
                }
                if (segment == nullptr   || segment->getResource() == nullptr
                    || segment->getResource()->getResourceFile().empty() ) {
                    track->removeSlot(slot);
                }

            } // end for else

        } // end for  track->getSortedSlots()
    }
}

static  int64_t getMaxTargetEnd(std::shared_ptr<cut::model::NLEModel> &nModel)  {
    int64_t targetEnd = -1;
    for (auto &track : nModel->getTracks()) {
        if (getTrackType(track) == cut::model::NLETrackType::VIDEO) {
            track->timeSort();
            int64_t trackEnd = track->getMaxEnd();
            if (targetEnd == -1 || trackEnd > targetEnd) {
                targetEnd = trackEnd;
            }
        }

    }
    return targetEnd;
}

static std::shared_ptr<NLETrackSlot> convertMaterialToVideo(std::shared_ptr<SMutableMaterial> material) {
    std::shared_ptr<cut::model::NLEResourceAV> node = material;

    auto segment = std::make_shared<cut::model::NLESegmentVideo>();
    segment->setAVFile(node);
    auto duration = std::max(node->getDuration() , material->getEndTime() - material->getStartTime());
    if (duration > 0) {
        segment->setTimeClipStart(0);

        segment->setTimeClipEnd(duration);
        material->setDuration(duration);

    } else {
        segment->setTimeClipStart(0);
        segment->setTimeClipEnd(1);
    }
    auto slot = std::make_shared<NLETrackSlot>();
    slot->setMainSegment(segment);
    slot->setDuration(segment->getDuration());
    setMutableNode(node);
    setMutableVideo(slot);
    return slot;

}



/**
 * 添加视频到MaterialSlot里
 * @param track
 * @param material
 */
static void addMaterialToMainTrack(std::shared_ptr<cut::model::NLETrack> mainTrack,
                                   std::shared_ptr<SMutableMaterial> material) {
    std::vector<std::shared_ptr<NLETrackSlot>> slots = mainTrack->getSortedSlots();
    std::shared_ptr<NLETrackSlot> materialSlot = convertMaterialToVideo(material);
    ///默认添加到素材资源最后，从所有Slot末尾往前找，一直到第一个素材资源或者片头标志Slot
    int i = slots.size() - 1;
    for(; i >= 0;i --){
        auto slot = slots[i];
        if(hasMutableVideo(slot) || ScriptUtils::isClipAtHead(slot)){
            mainTrack->addSlotAfterSlot(materialSlot,slot);
            break;
        }
    }
    ///如果都没找到，则代表不存在片头，直接末日添加到头部
    if(i < 0){
        mainTrack->addSlotAtStart(materialSlot);
    }
}


/**
 * 主轨里删除 手动删除资源
 * @param mainTrack
 * @param material
 */
static void removeMaterialAtMainTrack(std::shared_ptr<cut::model::NLETrack> mainTrack,
                                   std::shared_ptr<SMutableMaterial> material) {
    for (auto &slot : mainTrack->getSlots()) {
        auto videoSegment = cut::model::NLESegmentVideo::dynamicCast(slot->getMainSegment());
        if (videoSegment && videoSegment->getAVFile()
            && videoSegment->getAVFile()->getUUID() == material->getUUID()) {
            mainTrack->removeSlot(slot);
            break;
        }
    }
}

static void clearMaterialAtMainTrack(std::shared_ptr<cut::model::NLETrack> mainTrack) {
    for (auto &slot : mainTrack->getSlots()) {
        if(hasMutableVideo(slot)){
            mainTrack->removeSlot(slot);
        }
    }
}


static std::vector<std::shared_ptr<SMutableMaterial>> getMaterialAtTrack(
        std::shared_ptr<cut::model::NLETrack> track) {
    std::vector<std::shared_ptr<SMutableMaterial>> materials;
    for (auto &slot : track->getSlots()) {
        if(hasMutableVideo(slot)){
            auto videoSegment = cut::model::NLESegmentVideo::dynamicCast(slot->getMainSegment()
                    );
            if (videoSegment && videoSegment->getAVFile()) {
                materials.push_back(SMutableMaterial::dynamicCast(videoSegment->getAVFile()));
            }
        }
    }
    return materials;
}


/* --------------- ScriptModel -> NLE逻辑 ------------- */
/**
 * 通过节点上的extra字段来添加到对应的层级上
 * @param slot
 */
static void addExtraForXNode(std::shared_ptr<cut::model::NLETrackSlot> &slot) {

    if (std::shared_ptr<cut::model::NLESegment> segment = slot->getMainSegment()) {
        std::shared_ptr<NLEResourceNode> node ;
        // 音视频走这个
        if (auto mediaSegment = cut::model::NLESegmentAudio::dynamicCast(segment)) {
             node = mediaSegment->getAVFile();
        } else {
             node = segment->getResource();
        }
        if (node) {
            auto keys = node->getExtraKeys();
            for(auto  scri_key : keys) {
                if (scri_key.rfind(ExtraNodeKey) == 0) {
                   auto key =  scri_key.substr(ExtraNodeKey.length());
                   node->setExtra(key, node->getExtra(scri_key));
//                    node->setExtra(scri_key, "");

                } else if (scri_key.rfind(ExtraSegmentKey) == 0) {
                    auto key =  scri_key.substr(ExtraSegmentKey.length());
                    segment->setExtra(key, node->getExtra(scri_key));
//                    node->setExtra(scri_key, "");

                } else if (scri_key.rfind(ExtraSlotKey) == 0) {
                    auto key =  scri_key.substr(ExtraSlotKey.length());
                    slot->setExtra(key, node->getExtra(scri_key));
//                    node->setExtra(scri_key, "");

                }
            }

        }

    }
}

static std::vector<std::shared_ptr<cut::model::NLESegment>> getMutableSegmentsByType(
        cut::model::NLEResType type,
        std::shared_ptr<cut::model::NLEModel> nleModel) {
    std::vector<std::shared_ptr<cut::model::NLESegment>> segments;

    for (auto &track : nleModel->getTracks()) {
        for (auto &slot : track->getSortedSlots()) {
            auto seg = slot->getMainSegment();
            if (seg != nullptr) {
                auto res = seg->getResource();
                if (res != nullptr) {
                    if (res->getResourceType() == type) {
                        segments.push_back(seg);
                    }
                }
            }
//            }
        }
    }

    return segments;
}

static std::vector<std::shared_ptr<cut::model::NLESegment>> getAllMutableSegments(
        std::shared_ptr<cut::model::NLEModel> nleModel) {
    std::vector<std::shared_ptr<cut::model::NLESegment>> segments;
    
    for(auto &track : nleModel->getTracks()) {
        for(auto &slot : track->getSortedSlots()) {
                if(auto seg = slot->getMainSegment()){
                    if(auto res = seg->getResource()){
                        segments.push_back(seg);
                    }
                }
        }
    }
    
    return segments;
}

/**
 * 添加目录的Track
 * @param subTitles  字幕结果
 * @return
 */
static std::shared_ptr<cut::model::NLETrack> getSubTitleTrack(
        std::vector<std::shared_ptr<SubTitle>> subTitles ) {
    auto sub_title_track = std::make_shared<NLETrack>();
    for(auto &sub_title : subTitles) {
        if (sub_title  && sub_title->getEndTime() - sub_title->getStartTime() > 0) {
            auto sub_title_segment = std::make_shared<NLESegmentTextSticker>();
            sub_title_segment->setContent(sub_title->getSubTitle());
            sub_title_segment->setStyle(sub_title->getStyleText());


            auto sub_title_slot = std::make_shared<NLETrackSlot>();
            sub_title_slot->setMainSegment(sub_title_segment);
            sub_title_slot->setStartTime(sub_title->getStartTime());
            sub_title_slot->setEndTime(sub_title->getEndTime());
            sub_title_slot->setTransformX(sub_title->getTranX());
            sub_title_slot->setTransformY(sub_title->getTranY());
            sub_title_slot->setScale(sub_title->getScale());

            sub_title_track->addSlot(sub_title_slot);
        }
    }
    return sub_title_track;

}

/**
 * 判断两个时间范围是否有交集
 *
 * @param addedStartTime  比较时间段开始时间
 * @param addedEndTime    比较时间段结束时间
 * @param fixedStartTime 参考时间段开始时间
 * @param fixedEndTime   参考时间段结束时间
 */
static bool checkTimesHasOverlap(cut::model::NLETime addedStartTime,
                                 cut::model::NLETime addedEndTime,
                                 cut::model::NLETime fixedStartTime,
                                 cut::model::NLETime fixedEndTime) {
    return (addedStartTime  >= fixedStartTime && addedStartTime  <= fixedEndTime)
    || (addedEndTime  >= fixedStartTime && addedEndTime  <= fixedEndTime);
}


