//
// Created by Steven on 2021/2/7.
//

#ifndef TEMPLATECONSUMERAPP_CUTSAMECONSUMERHELPER_H
#define TEMPLATECONSUMERAPP_CUTSAMECONSUMERHELPER_H

#include "model.hpp"
#include "CutSameConsumerConst.hpp"
#include <fstream>
#include <string>
#include <cstdio>
#include <dirent.h>
#include <algorithm>

#if __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLEResourceNode.h>
#include <NLEPlatform/NLESequenceNode.h>
#include <NLEPlatform/NLEResType.h>
#else

#include <NLEResourceNode.h>
#include <NLESequenceNode.h>
#include <NLEResType.h>

#endif

using namespace CutSame;
using namespace cut::model;

static bool isCovertSuccess(int32_t resultCode) {
    return true;
//    assert(resultCode == CONVERT_RESULT_SUCCESS);
//    return resultCode == CONVERT_RESULT_SUCCESS;
}

static void convertFailClearSlot(std::shared_ptr<NLETrack> &nleTrack) {
    nleTrack->clearSlot();
}

static void convertFailClearTrack(const std::shared_ptr<NLEModel> &nleModel) {
    nleModel->clearTrack();
}

static void tagNLENodeCutSme(std::shared_ptr<NLENode> &nleNode) {
    nleNode->setExtra(EXTRA_KEY_BUSINESS, EXTRA_VAL_CUTSAME);
}

static bool isTagNLENodeCutSame(const std::shared_ptr<NLENode> &nleNode) {
    return nleNode->getExtra(EXTRA_KEY_BUSINESS) == EXTRA_VAL_CUTSAME;
}

static bool isMutableTMMaterial(const std::shared_ptr<TemplateModel> &tModel,
                                const std::shared_ptr<Material> &mat) {
    const auto mutMaterials = tModel->get_mutable_config()->get_mutable_materials();
    for (const auto &config: mutMaterials) {
        if (mat->get_id() == config->get_id()) {
            return true;
        }
    }
    return false;
}

static void putCutSameInfo(const std::shared_ptr<TemplateModel> &tModel,
                           const std::shared_ptr<Material> &tMat,
                           std::shared_ptr<NLENode> &nSeg) {
    nSeg->setExtra(EXTRA_KEY_CUTSAME_MATERIAL_ID, tMat->get_id());
    if (isMutableTMMaterial(tModel, tMat)) {
        nSeg->setExtra(EXTRA_KEY_CUTSAME_IS_MUTABLE, TRUE);
    }
}

static bool isTmMaterialInvalid(const std::shared_ptr<Material> &mat) {
    return mat == nullptr || mat->get_id().empty();
}

// todo to map 增加查找效率
template<typename T>
static std::shared_ptr<T>
getTemplateModelMaterial(const std::shared_ptr<TemplateModel> &tModel,
                         const std::string &materialId) {
    const auto &materials = tModel->get_materials();
    for (const auto &mat : materials->get_videos()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_audios()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_stickers()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_texts()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_effects()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_audio_effects()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_audio_fades()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_canvases()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_chromas()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_images()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_masks()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_material_animations()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_transitions()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_placeholders()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_text_templates()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    for (const auto &mat : materials->get_speeds()) {
        if (materialId == mat->get_id()) {
            return std::dynamic_pointer_cast<T>(mat);
        }
    }
    LOGGER->w("TMNLEC: material not found");
    return std::make_shared<T>();
}

template<typename T>
static std::shared_ptr<T>
getTemplateModelRefMaterial(const std::shared_ptr<TemplateModel> &tModel, const std::vector<std::string> &refIds) {
    for (const auto &refId: refIds) {
        const auto &tRefMaterial = getTemplateModelMaterial<T>(tModel, refId);
        auto tRefMaterialT = std::dynamic_pointer_cast<T>(tRefMaterial);
        if (tRefMaterialT == nullptr || isTmMaterialInvalid(tRefMaterial)) {
            continue;
        }
        return tRefMaterialT;
    }
    assert("material not found");
    return std::make_shared<T>();
}

static std::shared_ptr<MaterialEffect>
getTemplateModelMaterialEffect(const std::shared_ptr<TemplateModel> &tModel, const std::vector<std::string> &refIds, const std::string &effectType) {
    for (const auto &refId: refIds) {
        const auto &tMatEffect = getTemplateModelMaterial<MaterialEffect>(tModel, refId);
        auto tRefMaterialT = std::dynamic_pointer_cast<MaterialEffect>(tMatEffect);
        if (tRefMaterialT == nullptr || isTmMaterialInvalid(tMatEffect) || tMatEffect->get_type() != effectType) {
            continue;
        }
        return tRefMaterialT;
    }
    assert("material not found");
    return std::make_shared<MaterialEffect>();
}

static std::shared_ptr<Segment>
getEffectSegmentByMaterial(const std::shared_ptr<TemplateModel> &tModel, const std::string &tMatId) {
    for (const auto &track: tModel->get_tracks()) {
        for (const auto &segment: track->get_segments()) {
            if (segment->get_material_id() == tMatId) {
                return segment;
            }
        }
    }

    return std::make_shared<Segment>();
}

// copy from vesdk
static std::vector<float> transferTrimPointXtoSeqPointX(std::vector<float> curveSpeedPointX, std::vector<float> curveSpeedPointY) {
    float tSum = 0;
    int m_iAnchorNum = curveSpeedPointX.size();
    auto SeqPointX = std::vector<float>();
    SeqPointX.push_back(0);
    for (int i = 0; i < m_iAnchorNum - 1; i++) {
        float aY = (curveSpeedPointY[i + 1] + curveSpeedPointY[i]) * 0.5f;
        float dX = curveSpeedPointX[i + 1] - curveSpeedPointX[i];
        tSum += dX / aY;
        SeqPointX.push_back(tSum);
    }

    for (int i = 1; i < m_iAnchorNum; i++) {
        SeqPointX[i] = SeqPointX[i] / tSum;
    }
    return SeqPointX;
}

// copy from vesdk
static double calculateAveCurveSpeedRatio(std::vector<float> m_vPointX, std::vector<float> m_vPointY) {
    if(m_vPointX.empty() || m_vPointY.empty()){
        return 0;
    }
    double aveSpeed;

    double srcSum = 0;

    for (int i = 0; i < m_vPointX.size() - 1; i++) {

        double aY = (m_vPointY[i + 1] + m_vPointY[i]) * 0.5;
        double dX = (m_vPointX[i + 1] - m_vPointX[i]);

        srcSum += aY * dX;
    }

    aveSpeed = srcSum;

    return aveSpeed;
};

/**
 * 获取指定目录下的otf/ttf字体文件路径
 * @param fontDir 目录path   如果传入的已经是字体路径，则直接返回
 * @return fontDir
 */
std::string getFontPathInDir(const std::string &fontDir, const std::string &workspace) {
    if (fontDir.empty()) {
        return fontDir;
    }

    if (fontDir.find(".otf") != std::string::npos || fontDir.find(".ttf") != std::string::npos) {
        return fontDir;
    }

#if __V_IPHONE_PLATFORM__
    auto fullPath = workspace + "/" + fontDir;
#else
    auto fullPath = fontDir;
#endif
    DIR *dir = opendir(fullPath.c_str());
    if (dir == nullptr) {
        return "";
    }
    struct dirent *fileName;
    while ((fileName = readdir(dir)) != nullptr) {
        std::string tmpStr{fileName->d_name};
        std::string nameStr = std::string(fileName->d_name);
        std::transform(nameStr.begin(), nameStr.end(), nameStr.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        if (nameStr.find(".otf") != std::string::npos ||
            nameStr.find(".ttf") != std::string::npos) {
            closedir(dir);
            return fontDir + "/" + tmpStr;
        }
    }

    closedir(dir);
    return "";
}

#endif //TEMPLATECONSUMERAPP_CUTSAMECONSUMERHELPER_H
