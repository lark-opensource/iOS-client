//
// Created by Steven on 2021/1/25.
//

#ifndef TEMPLATECONSUMERAPP_TEMPLATECONSUMER_H
#define TEMPLATECONSUMERAPP_TEMPLATECONSUMER_H

#include <memory>
#include <vector>

namespace CutSame {
    class TemplateModel;
    class MaterialVideo;
}

namespace cut::model {
    class NLEModel;
    class NLETrackSlot;
}

namespace TemplateConsumer {
    class VideoMaterial;

    class TextMaterial;

    class CutSameConsumer {
    public:
        // 给NLEModel添加个剪同款模板
        static int32_t addCutSame(const std::shared_ptr<cut::model::NLEModel> &nModel,
                                  const std::shared_ptr<CutSame::TemplateModel> &tModel);

        // 修剪NLEModel二次编辑的时长
        static void trimCutSame(const std::shared_ptr<cut::model::NLEModel> &nModel,
                                const std::shared_ptr<CutSame::TemplateModel> &tModel);

        // 移除NLEModel中的所有跟剪同款有关的属性
        static int32_t removeCutSame(const std::shared_ptr<cut::model::NLEModel> &nModel);

        // 移除NLEModel中的所有跟剪同款无关的属性
        static int32_t onlyCutSame(const std::shared_ptr<cut::model::NLEModel> &nModel);

        // 获取剪同款的所有视频素材
        static std::vector<VideoMaterial> getVideoMaterials(const std::shared_ptr<cut::model::NLEModel> &nModel);

        // 获取剪同款的所有文字素材
        static std::vector<TextMaterial> getTextMaterials(const std::shared_ptr<cut::model::NLEModel> &nModel);

        // 设置剪同款视频素材
        static void setVideoMaterial(const std::shared_ptr<cut::model::NLEModel> &nModel, const VideoMaterial &video);

        // 设置剪同款文字素材
        static void setTextMaterial(const std::shared_ptr<cut::model::NLEModel> &nModel, const TextMaterial &text);
        
        // 根据material id，查找对应的NLETrackSlot
        static std::shared_ptr<cut::model::NLETrackSlot> getTrackSlot(const std::shared_ptr<cut::model::NLEModel> &nModel, const std::string &material_id);

        // 获得模板画布ratio
        static float getRatio(const std::shared_ptr<CutSame::TemplateModel> &tModel);

        // 获得模板duration
        static int64_t getDuration(const std::shared_ptr<CutSame::TemplateModel> &tModel);

        static void updateRelativeSizeWhileGlobalCanvasChanged(const std::shared_ptr<cut::model::NLEModel> &nModel, float globalCanvasRatio, float oldGlobalCanvasRatio);
    };
}

#endif //TEMPLATECONSUMERAPP_TEMPLATECONSUMER_H
