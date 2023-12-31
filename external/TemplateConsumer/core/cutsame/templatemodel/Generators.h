//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <nlohmann/json.hpp>

#include <vector>
#include <string>

#include "model.hpp"

using nlohmann::json;

namespace nlohmann {
    template <typename T>
    struct adl_serializer<std::shared_ptr<T>> {
        static void to_json(json & j, const std::shared_ptr<T> & opt) {
            if (!opt) j = nullptr; else j = *opt;
        }

        static void from_json(const json & j, std::shared_ptr<T>& value) {
            if (j.is_null()) value = std::make_shared<T>(); else value = std::shared_ptr<T>(new T(j.get<T>()));
        }
    };
}
namespace CutSame {
    template <typename T>
    inline std::vector<T> get_vector(const std::string& jsonString) {
        try {
            json j = nlohmann::json::parse(jsonString);
            return j.get<std::vector<T>>();
        } catch(...) {
            return std::vector<T>();
        }
    }

    template <typename T>
    inline std::string vector_to_string(const std::vector<T>& objects) {
        try {
            json j = json();
            j = objects;
            std::string result = j.dump();
            return result;
        } catch(...) {
            return "";
        }
    }

    inline json get_untyped(const json & j, const char * property) {
        if (j.find(property) != j.end()) {
            return j.at(property).get<json>();
        }
        return json();
    }

    inline json get_untyped(const json & j, std::string property) {
        return get_untyped(j, property.data());
    }

    template <typename T>
    inline std::shared_ptr<T> get_optional(const json & j, const char * property) {
        if (j.find(property) != j.end()) {
            return j.at(property).get<std::shared_ptr<T>>();
        }
        return std::shared_ptr<T>();
    }

    template <typename T>
    inline std::shared_ptr<T> get_optional(const json & j, std::string property) {
        return get_optional<T>(j, property.data());
    }

    template <typename T>
    inline T get_optional_with_default(const json & j, const char * property,  T(*defaultValueFactory)()) {
        if (j.find(property) != j.end()) {
            try {
             return j.at(property).get<T>();
            } catch(...) {}
        }
        return defaultValueFactory();
    }

    void from_json(const json & j, CutSame::DependencyResource & x);
    void to_json(json & j, const CutSame::DependencyResource & x);
    void fromJson(const std::string& jsongString, CutSame::DependencyResource & x);
    std::string toJson(const CutSame::DependencyResource & x);

    void from_json(const json & j, CutSame::EffectTemplate & x);
    void to_json(json & j, const CutSame::EffectTemplate & x);
    void fromJson(const std::string& jsongString, CutSame::EffectTemplate & x);
    std::string toJson(const CutSame::EffectTemplate & x);

    void from_json(const json & j, CutSame::Keyframe & x);
    void to_json(json & j, const CutSame::Keyframe & x);
    void fromJson(const std::string& jsongString, CutSame::Keyframe & x);
    std::string toJson(const CutSame::Keyframe & x);

    void from_json(const json & j, CutSame::Material & x);
    void to_json(json & j, const CutSame::Material & x);
    void fromJson(const std::string& jsongString, CutSame::Material & x);
    std::string toJson(const CutSame::Material & x);

    void from_json(const json & j, CutSame::TailSegment & x);
    void to_json(json & j, const CutSame::TailSegment & x);
    void fromJson(const std::string& jsongString, CutSame::TailSegment & x);
    std::string toJson(const CutSame::TailSegment & x);

    void from_json(const json & j, CutSame::CanvasConfig & x);
    void to_json(json & j, const CutSame::CanvasConfig & x);
    void fromJson(const std::string& jsongString, CutSame::CanvasConfig & x);
    std::string toJson(const CutSame::CanvasConfig & x);

    void from_json(const json & j, CutSame::Config & x);
    void to_json(json & j, const CutSame::Config & x);
    void fromJson(const std::string& jsongString, CutSame::Config & x);
    std::string toJson(const CutSame::Config & x);

    void from_json(const json & j, CutSame::AdjustKeyframe & x);
    void to_json(json & j, const CutSame::AdjustKeyframe & x);
    void fromJson(const std::string& jsongString, CutSame::AdjustKeyframe & x);
    std::string toJson(const CutSame::AdjustKeyframe & x);

    void from_json(const json & j, CutSame::AudioKeyframe & x);
    void to_json(json & j, const CutSame::AudioKeyframe & x);
    void fromJson(const std::string& jsongString, CutSame::AudioKeyframe & x);
    std::string toJson(const CutSame::AudioKeyframe & x);

    void from_json(const json & j, CutSame::FilterKeyframe & x);
    void to_json(json & j, const CutSame::FilterKeyframe & x);
    void fromJson(const std::string& jsongString, CutSame::FilterKeyframe & x);
    std::string toJson(const CutSame::FilterKeyframe & x);

    void from_json(const json & j, CutSame::Point & x);
    void to_json(json & j, const CutSame::Point & x);
    void fromJson(const std::string& jsongString, CutSame::Point & x);
    std::string toJson(const CutSame::Point & x);

    void from_json(const json & j, CutSame::StickerKeyframe & x);
    void to_json(json & j, const CutSame::StickerKeyframe & x);
    void fromJson(const std::string& jsongString, CutSame::StickerKeyframe & x);
    std::string toJson(const CutSame::StickerKeyframe & x);

    void from_json(const json & j, CutSame::TextKeyframe & x);
    void to_json(json & j, const CutSame::TextKeyframe & x);
    void fromJson(const std::string& jsongString, CutSame::TextKeyframe & x);
    std::string toJson(const CutSame::TextKeyframe & x);

    void from_json(const json & j, CutSame::MaskConfig & x);
    void to_json(json & j, const CutSame::MaskConfig & x);
    void fromJson(const std::string& jsongString, CutSame::MaskConfig & x);
    std::string toJson(const CutSame::MaskConfig & x);

    void from_json(const json & j, CutSame::VideoKeyframe & x);
    void to_json(json & j, const CutSame::VideoKeyframe & x);
    void fromJson(const std::string& jsongString, CutSame::VideoKeyframe & x);
    std::string toJson(const CutSame::VideoKeyframe & x);

    void from_json(const json & j, CutSame::Keyframes & x);
    void to_json(json & j, const CutSame::Keyframes & x);
    void fromJson(const std::string& jsongString, CutSame::Keyframes & x);
    std::string toJson(const CutSame::Keyframes & x);

    void from_json(const json & j, CutSame::MaterialAudioEffect & x);
    void to_json(json & j, const CutSame::MaterialAudioEffect & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialAudioEffect & x);
    std::string toJson(const CutSame::MaterialAudioEffect & x);

    void from_json(const json & j, CutSame::MaterialAudioFade & x);
    void to_json(json & j, const CutSame::MaterialAudioFade & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialAudioFade & x);
    std::string toJson(const CutSame::MaterialAudioFade & x);

    void from_json(const json & j, CutSame::MaterialAudio & x);
    void to_json(json & j, const CutSame::MaterialAudio & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialAudio & x);
    std::string toJson(const CutSame::MaterialAudio & x);

    void from_json(const json & j, CutSame::AiBeats & x);
    void to_json(json & j, const CutSame::AiBeats & x);
    void fromJson(const std::string& jsongString, CutSame::AiBeats & x);
    std::string toJson(const CutSame::AiBeats & x);

    void from_json(const json & j, CutSame::UserDeleteAiBeats & x);
    void to_json(json & j, const CutSame::UserDeleteAiBeats & x);
    void fromJson(const std::string& jsongString, CutSame::UserDeleteAiBeats & x);
    std::string toJson(const CutSame::UserDeleteAiBeats & x);

    void from_json(const json & j, CutSame::MaterialBeat & x);
    void to_json(json & j, const CutSame::MaterialBeat & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialBeat & x);
    std::string toJson(const CutSame::MaterialBeat & x);

    void from_json(const json & j, CutSame::MaterialCanvas & x);
    void to_json(json & j, const CutSame::MaterialCanvas & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialCanvas & x);
    std::string toJson(const CutSame::MaterialCanvas & x);

    void from_json(const json & j, CutSame::MaterialChroma & x);
    void to_json(json & j, const CutSame::MaterialChroma & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialChroma & x);
    std::string toJson(const CutSame::MaterialChroma & x);

    void from_json(const json & j, CutSame::AdjustParamsInfo & x);
    void to_json(json & j, const CutSame::AdjustParamsInfo & x);
    void fromJson(const std::string& jsongString, CutSame::AdjustParamsInfo & x);
    std::string toJson(const CutSame::AdjustParamsInfo & x);

    void from_json(const json & j, CutSame::MaterialEffect & x);
    void to_json(json & j, const CutSame::MaterialEffect & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialEffect & x);
    std::string toJson(const CutSame::MaterialEffect & x);

    void from_json(const json & j, CutSame::MaterialImage & x);
    void to_json(json & j, const CutSame::MaterialImage & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialImage & x);
    std::string toJson(const CutSame::MaterialImage & x);

    void from_json(const json & j, CutSame::MaterialMask & x);
    void to_json(json & j, const CutSame::MaterialMask & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialMask & x);
    std::string toJson(const CutSame::MaterialMask & x);

    void from_json(const json & j, CutSame::MaterialAnimation & x);
    void to_json(json & j, const CutSame::MaterialAnimation & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialAnimation & x);
    std::string toJson(const CutSame::MaterialAnimation & x);

    void from_json(const json & j, CutSame::Animations & x);
    void to_json(json & j, const CutSame::Animations & x);
    void fromJson(const std::string& jsongString, CutSame::Animations & x);
    std::string toJson(const CutSame::Animations & x);

    void from_json(const json & j, CutSame::MaterialPlaceholder & x);
    void to_json(json & j, const CutSame::MaterialPlaceholder & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialPlaceholder & x);
    std::string toJson(const CutSame::MaterialPlaceholder & x);

    void from_json(const json & j, CutSame::RealtimeDenoises & x);
    void to_json(json & j, const CutSame::RealtimeDenoises & x);
    void fromJson(const std::string& jsongString, CutSame::RealtimeDenoises & x);
    std::string toJson(const CutSame::RealtimeDenoises & x);

    void from_json(const json & j, CutSame::CurveSpeed & x);
    void to_json(json & j, const CutSame::CurveSpeed & x);
    void fromJson(const std::string& jsongString, CutSame::CurveSpeed & x);
    std::string toJson(const CutSame::CurveSpeed & x);

    void from_json(const json & j, CutSame::MaterialSpeed & x);
    void to_json(json & j, const CutSame::MaterialSpeed & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialSpeed & x);
    std::string toJson(const CutSame::MaterialSpeed & x);

    void from_json(const json & j, CutSame::MaterialSticker & x);
    void to_json(json & j, const CutSame::MaterialSticker & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialSticker & x);
    std::string toJson(const CutSame::MaterialSticker & x);

    void from_json(const json & j, CutSame::MaterialTailLeader & x);
    void to_json(json & j, const CutSame::MaterialTailLeader & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialTailLeader & x);
    std::string toJson(const CutSame::MaterialTailLeader & x);

    void from_json(const json & j, CutSame::MaterialResource & x);
    void to_json(json & j, const CutSame::MaterialResource & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialResource & x);
    std::string toJson(const CutSame::MaterialResource & x);

    void from_json(const json & j, CutSame::MaterialTextTemplate & x);
    void to_json(json & j, const CutSame::MaterialTextTemplate & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialTextTemplate & x);
    std::string toJson(const CutSame::MaterialTextTemplate & x);

    void from_json(const json & j, CutSame::MaterialText & x);
    void to_json(json & j, const CutSame::MaterialText & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialText & x);
    std::string toJson(const CutSame::MaterialText & x);

    void from_json(const json & j, CutSame::MaterialTransition & x);
    void to_json(json & j, const CutSame::MaterialTransition & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialTransition & x);
    std::string toJson(const CutSame::MaterialTransition & x);

    void from_json(const json & j, CutSame::Crop & x);
    void to_json(json & j, const CutSame::Crop & x);
    void fromJson(const std::string& jsongString, CutSame::Crop & x);
    std::string toJson(const CutSame::Crop & x);

    void from_json(const json & j, CutSame::GamePlay & x);
    void to_json(json & j, const CutSame::GamePlay & x);
    void fromJson(const std::string& jsongString, CutSame::GamePlay & x);
    std::string toJson(const CutSame::GamePlay & x);

    void from_json(const json & j, CutSame::TypePathInfo & x);
    void to_json(json & j, const CutSame::TypePathInfo & x);
    void fromJson(const std::string& jsongString, CutSame::TypePathInfo & x);
    std::string toJson(const CutSame::TypePathInfo & x);

    void from_json(const json & j, CutSame::Stable & x);
    void to_json(json & j, const CutSame::Stable & x);
    void fromJson(const std::string& jsongString, CutSame::Stable & x);
    std::string toJson(const CutSame::Stable & x);

    void from_json(const json & j, CutSame::MaterialVideo & x);
    void to_json(json & j, const CutSame::MaterialVideo & x);
    void fromJson(const std::string& jsongString, CutSame::MaterialVideo & x);
    std::string toJson(const CutSame::MaterialVideo & x);

    void from_json(const json & j, CutSame::Materials & x);
    void to_json(json & j, const CutSame::Materials & x);
    void fromJson(const std::string& jsongString, CutSame::Materials & x);
    std::string toJson(const CutSame::Materials & x);

    void from_json(const json & j, CutSame::MutableMaterial & x);
    void to_json(json & j, const CutSame::MutableMaterial & x);
    void fromJson(const std::string& jsongString, CutSame::MutableMaterial & x);
    std::string toJson(const CutSame::MutableMaterial & x);

    void from_json(const json & j, CutSame::MutableConfig & x);
    void to_json(json & j, const CutSame::MutableConfig & x);
    void fromJson(const std::string& jsongString, CutSame::MutableConfig & x);
    std::string toJson(const CutSame::MutableConfig & x);

    void from_json(const json & j, CutSame::PlatformClass & x);
    void to_json(json & j, const CutSame::PlatformClass & x);
    void fromJson(const std::string& jsongString, CutSame::PlatformClass & x);
    std::string toJson(const CutSame::PlatformClass & x);

    void from_json(const json & j, CutSame::RelationShip & x);
    void to_json(json & j, const CutSame::RelationShip & x);
    void fromJson(const std::string& jsongString, CutSame::RelationShip & x);
    std::string toJson(const CutSame::RelationShip & x);

    void from_json(const json & j, CutSame::Flip & x);
    void to_json(json & j, const CutSame::Flip & x);
    void fromJson(const std::string& jsongString, CutSame::Flip & x);
    std::string toJson(const CutSame::Flip & x);

    void from_json(const json & j, CutSame::Clip & x);
    void to_json(json & j, const CutSame::Clip & x);
    void fromJson(const std::string& jsongString, CutSame::Clip & x);
    std::string toJson(const CutSame::Clip & x);

    void from_json(const json & j, CutSame::Timerange & x);
    void to_json(json & j, const CutSame::Timerange & x);
    void fromJson(const std::string& jsongString, CutSame::Timerange & x);
    std::string toJson(const CutSame::Timerange & x);

    void from_json(const json & j, CutSame::Segment & x);
    void to_json(json & j, const CutSame::Segment & x);
    void fromJson(const std::string& jsongString, CutSame::Segment & x);
    std::string toJson(const CutSame::Segment & x);

    void from_json(const json & j, CutSame::Track & x);
    void to_json(json & j, const CutSame::Track & x);
    void fromJson(const std::string& jsongString, CutSame::Track & x);
    std::string toJson(const CutSame::Track & x);

    void from_json(const json & j, CutSame::CoverDraft & x);
    void to_json(json & j, const CutSame::CoverDraft & x);
    void fromJson(const std::string& jsongString, CutSame::CoverDraft & x);
    std::string toJson(const CutSame::CoverDraft & x);

    void from_json(const json & j, CutSame::CoverTemplate & x);
    void to_json(json & j, const CutSame::CoverTemplate & x);
    void fromJson(const std::string& jsongString, CutSame::CoverTemplate & x);
    std::string toJson(const CutSame::CoverTemplate & x);

    void from_json(const json & j, CutSame::CoverFrameInfo & x);
    void to_json(json & j, const CutSame::CoverFrameInfo & x);
    void fromJson(const std::string& jsongString, CutSame::CoverFrameInfo & x);
    std::string toJson(const CutSame::CoverFrameInfo & x);

    void from_json(const json & j, CutSame::CoverImageInfo & x);
    void to_json(json & j, const CutSame::CoverImageInfo & x);
    void fromJson(const std::string& jsongString, CutSame::CoverImageInfo & x);
    std::string toJson(const CutSame::CoverImageInfo & x);

    void from_json(const json & j, CutSame::CoverText & x);
    void to_json(json & j, const CutSame::CoverText & x);
    void fromJson(const std::string& jsongString, CutSame::CoverText & x);
    std::string toJson(const CutSame::CoverText & x);

    void from_json(const json & j, CutSame::CoverMaterials & x);
    void to_json(json & j, const CutSame::CoverMaterials & x);
    void fromJson(const std::string& jsongString, CutSame::CoverMaterials & x);
    std::string toJson(const CutSame::CoverMaterials & x);

    void from_json(const json & j, CutSame::Cover & x);
    void to_json(json & j, const CutSame::Cover & x);
    void fromJson(const std::string& jsongString, CutSame::Cover & x);
    std::string toJson(const CutSame::Cover & x);

    void from_json(const json & j, CutSame::TutorialInfo & x);
    void to_json(json & j, const CutSame::TutorialInfo & x);
    void fromJson(const std::string& jsongString, CutSame::TutorialInfo & x);
    std::string toJson(const CutSame::TutorialInfo & x);

    void from_json(const json & j, CutSame::TrackInfo & x);
    void to_json(json & j, const CutSame::TrackInfo & x);
    void fromJson(const std::string& jsongString, CutSame::TrackInfo & x);
    std::string toJson(const CutSame::TrackInfo & x);

    void from_json(const json & j, CutSame::ExtraInfo & x);
    void to_json(json & j, const CutSame::ExtraInfo & x);
    void fromJson(const std::string& jsongString, CutSame::ExtraInfo & x);
    std::string toJson(const CutSame::ExtraInfo & x);

    void from_json(const json & j, CutSame::TemplateModel & x);
    void to_json(json & j, const CutSame::TemplateModel & x);
    void fromJson(const std::string& jsongString, CutSame::TemplateModel & x);
    std::string toJson(const CutSame::TemplateModel & x);

    void from_json(const json & j, CutSame::TemplateText & x);
    void to_json(json & j, const CutSame::TemplateText & x);
    void fromJson(const std::string& jsongString, CutSame::TemplateText & x);
    std::string toJson(const CutSame::TemplateText & x);

    void from_json(const json & j, CutSame::TemplateParam & x);
    void to_json(json & j, const CutSame::TemplateParam & x);
    void fromJson(const std::string& jsongString, CutSame::TemplateParam & x);
    std::string toJson(const CutSame::TemplateParam & x);

    void from_json(const json & j, CutSame::TextSegment & x);
    void to_json(json & j, const CutSame::TextSegment & x);
    void fromJson(const std::string& jsongString, CutSame::TextSegment & x);
    std::string toJson(const CutSame::TextSegment & x);

    void from_json(const json & j, CutSame::TimeClipParam & x);
    void to_json(json & j, const CutSame::TimeClipParam & x);
    void fromJson(const std::string& jsongString, CutSame::TimeClipParam & x);
    std::string toJson(const CutSame::TimeClipParam & x);

    void from_json(const json & j, CutSame::VeConfig & x);
    void to_json(json & j, const CutSame::VeConfig & x);
    void fromJson(const std::string& jsongString, CutSame::VeConfig & x);
    std::string toJson(const CutSame::VeConfig & x);

    void from_json(const json & j, CutSame::VideoCompileParam & x);
    void to_json(json & j, const CutSame::VideoCompileParam & x);
    void fromJson(const std::string& jsongString, CutSame::VideoCompileParam & x);
    std::string toJson(const CutSame::VideoCompileParam & x);

    void from_json(const json & j, CutSame::VideoPreviewConfig & x);
    void to_json(json & j, const CutSame::VideoPreviewConfig & x);
    void fromJson(const std::string& jsongString, CutSame::VideoPreviewConfig & x);
    std::string toJson(const CutSame::VideoPreviewConfig & x);

    void from_json(const json & j, CutSame::VideoSegment & x);
    void to_json(json & j, const CutSame::VideoSegment & x);
    void fromJson(const std::string& jsongString, CutSame::VideoSegment & x);
    std::string toJson(const CutSame::VideoSegment & x);

    void from_json(const json & j, CutSame::AutogenModel & x);
    void to_json(json & j, const CutSame::AutogenModel & x);
    void fromJson(const std::string& jsongString, CutSame::AutogenModel & x);
    std::string toJson(const CutSame::AutogenModel & x);

    void from_json(const json & j, CutSame::PlatformEnum & x);
    void to_json(json & j, const CutSame::PlatformEnum & x);

    void from_json(const json & j, CutSame::CropRatio & x);
    void to_json(json & j, const CutSame::CropRatio & x);

    void from_json(const json & j, CutSame::CoverType & x);
    void to_json(json & j, const CutSame::CoverType & x);
}
