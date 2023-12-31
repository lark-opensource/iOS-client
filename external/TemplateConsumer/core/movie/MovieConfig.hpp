//  To parse this JSON data, first install
//
//      json.hpp  https://github.com/nlohmann/json
//
//  Then include this file, and then do
//
//     MovieConfig data = nlohmann::json::parse(jsonString);

#pragma once

#include <nlohmann/json.hpp>

#include <optional>
#include <stdexcept>
#include <regex>

#ifndef NLOHMANN_OPT_HELPER
#define NLOHMANN_OPT_HELPER
namespace nlohmann {
    template <typename T>
    struct adl_serializer<std::shared_ptr<T>> {
        static void to_json(json & j, const std::shared_ptr<T> & opt) {
            if (!opt) j = nullptr; else j = *opt;
        }

        static std::shared_ptr<T> from_json(const json & j) {
            if (j.is_null()) return std::unique_ptr<T>(); else return std::unique_ptr<T>(new T(j.get<T>()));
        }
    };
}
#endif

namespace MovieConsumer {
    using nlohmann::json;

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

    struct Variant {
    public:
        Variant() = default;
        ~Variant() = default;

        Variant(float _value): fValue(_value),strValue(""), intValue(-1) {}
        Variant(std::string _strValue): strValue(_strValue), fValue(-1.0), intValue(-1) {}
        Variant(std::int64_t _intValue): intValue(_intValue), fValue(-1.0), strValue("") {}

        float fValue;
        std::string strValue;
        int64_t intValue;

        bool isFloat() const {
            return fValue >= 0;
        }

        bool isString() const {
            return !strValue.empty();
        }

        bool isInt() const {
            return intValue >= 0;
        }
    };

    using Ate = Variant;//std::variant<float, std::string>;

    class FrameUnifyBbox {
    public:
        FrameUnifyBbox() = default;
        virtual ~FrameUnifyBbox() = default;

    private:
        std::string methods;
        std::vector<double> cropBbox;

    public:
        const std::string & getMethods() const { return methods; }
        std::string & getMutableMethods() { return methods; }
        void setMethods(const std::string & value) { this->methods = value; }

        const std::vector<double> & getCropBbox() const { return cropBbox; }
        std::vector<double> & getMutableCropBbox() { return cropBbox; }
        void setCropBbox(const std::vector<double> & value) { this->cropBbox = value; }
    };

    class Meta {
    public:
        Meta() = default;
        virtual ~Meta() = default;

    private:
        int64_t height;
        int64_t width;
        std::vector<std::string> includes;
        std::string name;
        std::string path;
        int64_t rotation;

    public:
        const int64_t & getHeight() const { return height; }
        int64_t & getMutableHeight() { return height; }
        void setHeight(const int64_t & value) { this->height = value; }

        const int64_t & getWidth() const { return width; }
        int64_t & getMutableWidth() { return width; }
        void setWidth(const int64_t & value) { this->width = value; }

        const std::vector<std::string> & getIncludes() const { return includes; }
        std::vector<std::string> & getMutableIncludes() { return includes; }
        void setIncludes(const std::vector<std::string> & value) { this->includes = value; }

        const std::string & getName() const { return name; }
        std::string & getMutableName() { return name; }
        void setName(const std::string & value) { this->name = value; }

        const std::string & getPath() const { return path; }
        std::string & getMutablePath() { return path; }
        void setPath(const std::string & value) { this->path = value; }

        const int64_t & getRotation() const { return rotation; }
        int64_t & getMutableRotation() { return rotation; }
        void setRotation(const int64_t & value) { this->rotation = value; }
    };

    class TextAnimationFilter {
    public:
        TextAnimationFilter() = default;
        virtual ~TextAnimationFilter() = default;

    private:
        std::string animIn;
        std::string animOut;
        int64_t animInDuration;
        int64_t animOutDuration;
        bool animLoop;

    public:
        const std::string & getAnimIn() const { return animIn; }
        std::string & getMutableAnimIn() { return animIn; }
        void setAnimIn(const std::string & value) { this->animIn = value; }

        const std::string & getAnimOut() const { return animOut; }
        std::string & getMutableAnimOut() { return animOut; }
        void setAnimOut(const std::string & value) { this->animOut = value; }

        const int64_t & getAnimInDuration() const { return animInDuration; }
        int64_t & getMutableAnimInDuration() { return animInDuration; }
        void setAnimInDuration(const int64_t & value) { this->animInDuration = value; }

        const int64_t & getAnimOutDuration() const { return animOutDuration; }
        int64_t & getMutableAnimOutDuration() { return animOutDuration; }
        void setAnimOutDuration(const int64_t & value) { this->animOutDuration = value; }

        const bool & getAnimLoop() const { return animLoop; }
        bool & getMutableAnimLoop() { return animLoop; }
        void setAnimLoop(const bool & value) { this->animLoop = value; }
    };

    class TextStickerFilter {
    public:
        TextStickerFilter() = default;
        virtual ~TextStickerFilter() = default;

    private:
        double fontSize;
        int64_t typeSettingKind;
        int64_t alignType;
        std::string textColor;
        bool background;
        bool shadow;
        bool outline;
        double outlineWidth;
        std::string outlineColor;
        double lineGap;
        double charSpacing;
        double lineMaxWidth;
        std::string fontPath;

    public:
        const double & getFontSize() const { return fontSize; }
        double & getMutableFontSize() { return fontSize; }
        void setFontSize(const double & value) { this->fontSize = value; }

        const int64_t & getTypeSettingKind() const { return typeSettingKind; }
        int64_t & getMutableTypeSettingKind() { return typeSettingKind; }
        void setTypeSettingKind(const int64_t & value) { this->typeSettingKind = value; }

        const int64_t & getAlignType() const { return alignType; }
        int64_t & getMutableAlignType() { return alignType; }
        void setAlignType(const int64_t & value) { this->alignType = value; }

        const std::string & getTextColor() const { return textColor; }
        std::string & getMutableTextColor() { return textColor; }
        void setTextColor(const std::string & value) { this->textColor = value; }

        const bool & getBackground() const { return background; }
        bool & getMutableBackground() { return background; }
        void setBackground(const bool & value) { this->background = value; }

        const bool & getShadow() const { return shadow; }
        bool & getMutableShadow() { return shadow; }
        void setShadow(const bool & value) { this->shadow = value; }

        const bool & getOutline() const { return outline; }
        bool & getMutableOutline() { return outline; }
        void setOutline(const bool & value) { this->outline = value; }

        const double & getOutlineWidth() const { return outlineWidth; }
        double & getMutableOutlineWidth() { return outlineWidth; }
        void setOutlineWidth(const double & value) { this->outlineWidth = value; }

        const std::string & getOutlineColor() const { return outlineColor; }
        std::string & getMutableOutlineColor() { return outlineColor; }
        void setOutlineColor(const std::string & value) { this->outlineColor = value; }

        const double & getLineGap() const { return lineGap; }
        double & getMutableLineGap() { return lineGap; }
        void setLineGap(const double & value) { this->lineGap = value; }

        const double & getCharSpacing() const { return charSpacing; }
        double & getMutableCharSpacing() { return charSpacing; }
        void setCharSpacing(const double & value) { this->charSpacing = value; }

        const double & getLineMaxWidth() const { return lineMaxWidth; }
        double & getMutableLineMaxWidth() { return lineMaxWidth; }
        void setLineMaxWidth(const double & value) { this->lineMaxWidth = value; }

        const std::string & getFontPath() const { return fontPath; }
        std::string & getMutableFontPath() { return fontPath; }
        void setFontPath(const std::string & value) { this->fontPath = value; }
    };

    class TextTransformFilter {
    public:
        TextTransformFilter() = default;
        virtual ~TextTransformFilter() = default;

    private:
        double scaleX;
        double scaleY;
        double rotation;
        double positionX;
        double positionY;
        bool flipX;
        bool flipY;
        double alpha;
        double anchorX;
        double anchorY;

    public:
        const double & getScaleX() const { return scaleX; }
        double & getMutableScaleX() { return scaleX; }
        void setScaleX(const double & value) { this->scaleX = value; }

        const double & getScaleY() const { return scaleY; }
        double & getMutableScaleY() { return scaleY; }
        void setScaleY(const double & value) { this->scaleY = value; }

        const double & getRotation() const { return rotation; }
        double & getMutableRotation() { return rotation; }
        void setRotation(const double & value) { this->rotation = value; }

        const double & getPositionX() const { return positionX; }
        double & getMutablePositionX() { return positionX; }
        void setPositionX(const double & value) { this->positionX = value; }

        const double & getPositionY() const { return positionY; }
        double & getMutablePositionY() { return positionY; }
        void setPositionY(const double & value) { this->positionY = value; }

        const bool & getFlipX() const { return flipX; }
        bool & getMutableFlipX() { return flipX; }
        void setFlipX(const bool & value) { this->flipX = value; }

        const bool & getFlipY() const { return flipY; }
        bool & getMutableFlipY() { return flipY; }
        void setFlipY(const bool & value) { this->flipY = value; }

        const double & getAlpha() const { return alpha; }
        double & getMutableAlpha() { return alpha; }
        void setAlpha(const double & value) { this->alpha = value; }

        const double & getAnchorX() const { return anchorX; }
        double & getMutableAnchorX() { return anchorX; }
        void setAnchorX(const double & value) { this->anchorX = value; }

        const double & getAnchorY() const { return anchorY; }
        double & getMutableAnchorY() { return anchorY; }
        void setAnchorY(const double & value) { this->anchorY = value; }
    };

    class LyricsStyle {
    public:
        LyricsStyle() = default;
        virtual ~LyricsStyle() = default;

    private:
        TextStickerFilter textStickerFilter;
        TextAnimationFilter textAnimationFilter;
        TextTransformFilter textTransformFilter;

    public:
        const TextStickerFilter & getTextStickerFilter() const { return textStickerFilter; }
        TextStickerFilter & getMutableTextStickerFilter() { return textStickerFilter; }
        void setTextStickerFilter(const TextStickerFilter & value) { this->textStickerFilter = value; }

        const TextAnimationFilter & getTextAnimationFilter() const { return textAnimationFilter; }
        TextAnimationFilter & getMutableTextAnimationFilter() { return textAnimationFilter; }
        void setTextAnimationFilter(const TextAnimationFilter & value) { this->textAnimationFilter = value; }

        const TextTransformFilter & getTextTransformFilter() const { return textTransformFilter; }
        TextTransformFilter & getMutableTextTransformFilter() { return textTransformFilter; }
        void setTextTransformFilter(const TextTransformFilter & value) { this->textTransformFilter = value; }
    };

    class MusicLyric {
    public:
        MusicLyric() = default;
        virtual ~MusicLyric() = default;

    private:
        std::string text;
        int64_t startTimeStamp;
        int64_t endTimeStamp;

    public:
        const std::string & getText() const { return text; }
        std::string & getMutableText() { return text; }
        void setText(const std::string & value) { this->text = value; }

        const int64_t & getStartTimeStamp() const { return startTimeStamp; }
        int64_t & getMutableStartTimeStamp() { return startTimeStamp; }
        void setStartTimeStamp(const int64_t & value) { this->startTimeStamp = value; }

        const int64_t & getEndTimeStamp() const { return endTimeStamp; }
        int64_t & getMutableEndTimeStamp() { return endTimeStamp; }
        void setEndTimeStamp(const int64_t & value) { this->endTimeStamp = value; }
    };

    class MovieConfig {
    public:
        MovieConfig() = default;
        virtual ~MovieConfig() = default;

    private:
        std::vector<FrameUnifyBbox> frameUnifyBbox;
        std::string musicUrl;
        bool genPureAteVideo;
        bool genCmAteVideo;
        std::vector<std::vector<Ate>> imgAtEs;
        std::vector<std::vector<Ate>> cmAtEs;
        std::vector<Meta> metas;
        std::vector<int64_t> imgTimeStamps;
        std::vector<std::vector<double>> cmStartBboxs;
        std::vector<std::vector<double>> cmEndBboxs;
        std::vector<std::string> materialType;
        std::vector<int64_t> musicFadeInOutDur;
        std::vector<MusicLyric> musicLyrics;
        std::vector<LyricsStyle> lyricsStyles;
        std::shared_ptr<std::vector<double>> speed;
        std::shared_ptr<std::vector<double>> volume;
        std::shared_ptr<std::vector<int64_t>> startTime;
        std::shared_ptr<std::vector<int64_t>> endTime;
        std::shared_ptr<std::vector<std::string>> videoUrlList;
        std::shared_ptr<double> musicVolume;
        std::shared_ptr<bool> loopMusic;

    public:

        const std::vector<FrameUnifyBbox> & getFrameUnifyBbox() const { return frameUnifyBbox; }
        std::vector<FrameUnifyBbox> & getMutableFrameUnifyBbox() { return frameUnifyBbox; }
        void setFrameUnifyBbox(const std::vector<FrameUnifyBbox> & value) { this->frameUnifyBbox = value; }

        const std::string & getMusicUrl() const { return musicUrl; }
        std::string & getMutableMusicUrl() { return musicUrl; }
        void setMusicUrl(const std::string & value) { this->musicUrl = value; }

        const bool & getGenPureAteVideo() const { return genPureAteVideo; }
        bool & getMutableGenPureAteVideo() { return genPureAteVideo; }
        void setGenPureAteVideo(const bool & value) { this->genPureAteVideo = value; }

        const bool & getGenCmAteVideo() const { return genCmAteVideo; }
        bool & getMutableGenCmAteVideo() { return genCmAteVideo; }
        void setGenCmAteVideo(const bool & value) { this->genCmAteVideo = value; }

        const std::vector<std::vector<Ate>> & getImgAtEs() const { return imgAtEs; }
        std::vector<std::vector<Ate>> & getMutableImgAtEs() { return imgAtEs; }
        void setImgAtEs(const std::vector<std::vector<Ate>> & value) { this->imgAtEs = value; }

        const std::vector<std::string> & getMaterialType() const { return materialType; }
        std::vector<std::string> & getMutableMaterialType() { return materialType; }
        void setMaterialType(const std::vector<std::string> & value) { this->materialType = value; }

        const std::vector<std::vector<Ate>> & getCmAtEs() const { return cmAtEs; }
        std::vector<std::vector<Ate>> & getMutableCmAtEs() { return cmAtEs; }
        void setCmAtEs(const std::vector<std::vector<Ate>> & value) { this->cmAtEs = value; }

        const std::vector<Meta> & getMetas() const { return metas; }
        std::vector<Meta> & getMutableMetas() { return metas; }
        void setMetas(const std::vector<Meta> & value) { this->metas = value; }

        const std::vector<int64_t> & getImgTimeStamps() const { return imgTimeStamps; }
        std::vector<int64_t> & getMutableImgTimeStamps() { return imgTimeStamps; }
        void setImgTimeStamps(const std::vector<int64_t> & value) { this->imgTimeStamps = value; }

        const std::vector<std::vector<double>> & getCmStartBboxs() const { return cmStartBboxs; }
        std::vector<std::vector<double>> & getMutableCmStartBboxs() { return cmStartBboxs; }
        void setCmStartBboxs(const std::vector<std::vector<double>> & value) { this->cmStartBboxs = value; }

        const std::vector<std::vector<double>> & getCmEndBboxs() const { return cmEndBboxs; }
        std::vector<std::vector<double>> & getMutableCmEndBboxs() { return cmEndBboxs; }
        void setCmEndBboxs(const std::vector<std::vector<double>> & value) { this->cmEndBboxs = value; }

        const std::vector<int64_t> & getMusicFadeInOutDur() const { return musicFadeInOutDur; }
        std::vector<int64_t> & getMutableMusicFadeInOutDur() { return musicFadeInOutDur; }
        void setMusicFadeInOutDur(const std::vector<int64_t> & value) { this->musicFadeInOutDur = value; }

        const std::vector<MusicLyric> & getMusicLyrics() const { return musicLyrics; }
        std::vector<MusicLyric> & getMutableMusicLyrics() { return musicLyrics; }
        void setMusicLyrics(const std::vector<MusicLyric> & value) { this->musicLyrics = value; }

        const std::vector<LyricsStyle> & getLyricsStyles() const { return lyricsStyles; }
        std::vector<LyricsStyle> & getMutableLyricsStyles() { return lyricsStyles; }
        void setLyricsStyles(const std::vector<LyricsStyle> & value) { this->lyricsStyles = value; }

        std::shared_ptr<std::vector<double>> getSpeed() const { return speed; }
        void setSpeed(std::shared_ptr<std::vector<double>> value) { this->speed = value; }

        std::shared_ptr<std::vector<double>> getVolume() const { return volume; }
        void setVolume(std::shared_ptr<std::vector<double>> value) { this->volume = value; }

        std::shared_ptr<std::vector<int64_t>> getStartTime() const { return startTime; }
        void setStartTime(std::shared_ptr<std::vector<int64_t>> value) { this->startTime = value; }

        std::shared_ptr<std::vector<int64_t>> getEndTime() const { return endTime; }
        void setEndTime(std::shared_ptr<std::vector<int64_t>> value) { this->endTime = value; }

        std::shared_ptr<std::vector<std::string>> getVideoUrlList() const { return videoUrlList; }
        void setVideoUrlList(std::shared_ptr<std::vector<std::string>> value) { this->videoUrlList = value; }

        std::shared_ptr<double> getMusicVolume() const { return musicVolume; }
        void setMusicVolume(std::shared_ptr<double> value) { this->musicVolume = value; }

        std::shared_ptr<bool> getLoopMusic() const { return loopMusic; }
        void setLoopMusic(std::shared_ptr<bool> value) { this->loopMusic = value; }
    };
}

namespace nlohmann {
    void from_json(const json & j, MovieConsumer::FrameUnifyBbox & x);
    void to_json(json & j, const MovieConsumer::FrameUnifyBbox & x);

    void from_json(const json & j, MovieConsumer::Meta & x);
    void to_json(json & j, const MovieConsumer::Meta & x);

    void from_json(const json & j, MovieConsumer::TextAnimationFilter & x);
    void to_json(json & j, const MovieConsumer::TextAnimationFilter & x);

    void from_json(const json & j, MovieConsumer::TextStickerFilter & x);
    void to_json(json & j, const MovieConsumer::TextStickerFilter & x);

    void from_json(const json & j, MovieConsumer::TextTransformFilter & x);
    void to_json(json & j, const MovieConsumer::TextTransformFilter & x);

    void from_json(const json & j, MovieConsumer::LyricsStyle & x);
    void to_json(json & j, const MovieConsumer::LyricsStyle & x);

    void from_json(const json & j, MovieConsumer::MusicLyric & x);
    void to_json(json & j, const MovieConsumer::MusicLyric & x);

    void from_json(const json & j, MovieConsumer::MovieConfig & x);
    void to_json(json & j, const MovieConsumer::MovieConfig & x);

    void from_json(const json & j, MovieConsumer::Variant & x);
    void to_json(json & j, const MovieConsumer::Variant & x);

    void from_json(const json & j, MovieConsumer::Variant & x);
    void to_json(json & j, const MovieConsumer::Variant & x);

    inline void from_json(const json & j, MovieConsumer::FrameUnifyBbox& x) {
        x.setMethods(j.at("methods").get<std::string>());
        x.setCropBbox(j.at("crop_bbox").get<std::vector<double>>());
    }

    inline void to_json(json & j, const MovieConsumer::FrameUnifyBbox & x) {
        j = json::object();
        j["methods"] = x.getMethods();
        j["crop_bbox"] = x.getCropBbox();
    }

    inline void from_json(const json & j, MovieConsumer::Meta& x) {
        x.setHeight(j.at("height").get<int64_t>());
        x.setWidth(j.at("width").get<int64_t>());
        x.setIncludes(j.at("includes").get<std::vector<std::string>>());
        x.setName(j.at("name").get<std::string>());
        x.setPath(j.at("path").get<std::string>());
        x.setRotation(j.at("rotation").get<int64_t>());
    }

    inline void to_json(json & j, const MovieConsumer::Meta & x) {
        j = json::object();
        j["height"] = x.getHeight();
        j["width"] = x.getWidth();
        j["includes"] = x.getIncludes();
        j["name"] = x.getName();
        j["path"] = x.getPath();
        j["rotation"] = x.getRotation();
    }

    inline void from_json(const json & j, MovieConsumer::TextAnimationFilter& x) {
        x.setAnimIn(j.at("anim_in").get<std::string>());
        x.setAnimOut(j.at("anim_out").get<std::string>());
        x.setAnimInDuration(j.at("anim_in_duration").get<int64_t>());
        x.setAnimOutDuration(j.at("anim_out_duration").get<int64_t>());
        x.setAnimLoop(j.at("anim_loop").get<bool>());
    }

    inline void to_json(json & j, const MovieConsumer::TextAnimationFilter & x) {
        j = json::object();
        j["anim_in"] = x.getAnimIn();
        j["anim_out"] = x.getAnimOut();
        j["anim_in_duration"] = x.getAnimInDuration();
        j["anim_out_duration"] = x.getAnimOutDuration();
        j["anim_loop"] = x.getAnimLoop();
    }

    inline void from_json(const json & j, MovieConsumer::TextStickerFilter& x) {
        x.setFontSize(j.at("font_size").get<double>());
        x.setTypeSettingKind(j.at("type_setting_kind").get<int64_t>());
        x.setAlignType(j.at("align_type").get<int64_t>());
        x.setTextColor(j.at("text_color").get<std::string>());
        x.setBackground(j.at("background").get<bool>());
        x.setShadow(j.at("shadow").get<bool>());
        x.setOutline(j.at("outline").get<bool>());
        x.setOutlineWidth(j.at("outline_width").get<double>());
        x.setOutlineColor(j.at("outline_color").get<std::string>());
        x.setLineGap(j.at("line_gap").get<double>());
        x.setCharSpacing(j.at("char_spacing").get<double>());
        x.setLineMaxWidth(j.at("line_max_width").get<double>());
        x.setFontPath(j.at("font_path").get<std::string>());
    }

    inline void to_json(json & j, const MovieConsumer::TextStickerFilter & x) {
        j = json::object();
        j["font_size"] = x.getFontSize();
        j["type_setting_kind"] = x.getTypeSettingKind();
        j["align_type"] = x.getAlignType();
        j["text_color"] = x.getTextColor();
        j["background"] = x.getBackground();
        j["shadow"] = x.getShadow();
        j["outline"] = x.getOutline();
        j["outline_width"] = x.getOutlineWidth();
        j["outline_color"] = x.getOutlineColor();
        j["line_gap"] = x.getLineGap();
        j["char_spacing"] = x.getCharSpacing();
        j["line_max_width"] = x.getLineMaxWidth();
        j["font_path"] = x.getFontPath();
    }

    inline void from_json(const json & j, MovieConsumer::TextTransformFilter& x) {
        x.setScaleX(j.at("scale_x").get<double>());
        x.setScaleY(j.at("scale_y").get<double>());
        x.setRotation(j.at("rotation").get<double>());
        x.setPositionX(j.at("position_x").get<double>());
        x.setPositionY(j.at("position_y").get<double>());
        x.setFlipX(j.at("flip_x").get<int8_t>() == 0);
        x.setFlipY(j.at("flip_y").get<int8_t>() == 0);
        x.setAlpha(j.at("alpha").get<double>());
        x.setAnchorX(j.at("anchor_x").get<double>());
        x.setAnchorY(j.at("anchor_y").get<double>());
    }

    inline void to_json(json & j, const MovieConsumer::TextTransformFilter & x) {
        j = json::object();
        j["scale_x"] = x.getScaleX();
        j["scale_y"] = x.getScaleY();
        j["rotation"] = x.getRotation();
        j["position_x"] = x.getPositionX();
        j["position_y"] = x.getPositionY();
        j["flip_x"] = x.getFlipX();
        j["flip_y"] = x.getFlipY();
        j["alpha"] = x.getAlpha();
        j["anchor_x"] = x.getAnchorX();
        j["anchor_y"] = x.getAnchorY();
    }

    inline void from_json(const json & j, MovieConsumer::LyricsStyle& x) {
        x.setTextStickerFilter(j.at("text_sticker_filter").get<MovieConsumer::TextStickerFilter>());
        x.setTextAnimationFilter(j.at("text_animation_filter").get<MovieConsumer::TextAnimationFilter>());
        x.setTextTransformFilter(j.at("text_transform_filter").get<MovieConsumer::TextTransformFilter>());
    }

    inline void to_json(json & j, const MovieConsumer::LyricsStyle & x) {
        j = json::object();
        j["text_sticker_filter"] = x.getTextStickerFilter();
        j["text_animation_filter"] = x.getTextAnimationFilter();
        j["text_transform_filter"] = x.getTextTransformFilter();
    }

    inline void from_json(const json & j, MovieConsumer::MusicLyric& x) {
        x.setText(j.at("text").get<std::string>());
        x.setStartTimeStamp(j.at("start_time_stamp").get<int64_t>());
        x.setEndTimeStamp(j.at("end_time_stamp").get<int64_t>());
    }

    inline void to_json(json & j, const MovieConsumer::MusicLyric & x) {
        j = json::object();
        j["text"] = x.getText();
        j["start_time_stamp"] = x.getStartTimeStamp();
        j["end_time_stamp"] = x.getEndTimeStamp();
    }

    inline void from_json(const json & j, MovieConsumer::MovieConfig& x) {
        x.setFrameUnifyBbox(j.at("frame_unify_bbox").get<std::vector<MovieConsumer::FrameUnifyBbox>>());
        x.setMusicUrl(j.at("music_url").get<std::string>());
        x.setGenPureAteVideo(j.at("gen_pure_ate_video").get<bool>());
        x.setGenCmAteVideo(j.at("gen_cm_ate_video").get<bool>());
        x.setImgAtEs(j.at("img_ATEs").get<std::vector<std::vector<MovieConsumer::Ate>>>());
        x.setCmAtEs(j.at("CM_ATEs").get<std::vector<std::vector<MovieConsumer::Ate>>>());
        x.setMetas(j.at("metas").get<std::vector<MovieConsumer::Meta>>());
        x.setImgTimeStamps(j.at("img_time_stamps").get<std::vector<int64_t>>());
        x.setMaterialType(j.at("material_type").get<std::vector<std::string>>());
        x.setCmStartBboxs(j.at("cm_start_bboxs").get<std::vector<std::vector<double>>>());
        x.setCmEndBboxs(j.at("cm_end_bboxs").get<std::vector<std::vector<double>>>());
        x.setMusicFadeInOutDur(j.at("music_fade_in_out_dur").get<std::vector<int64_t>>());
        x.setMusicLyrics(j.at("music_lyrics").get<std::vector<MovieConsumer::MusicLyric>>());
        x.setLyricsStyles(j.at("lyrics_styles").get<std::vector<MovieConsumer::LyricsStyle>>());
        x.setSpeed(MovieConsumer::get_optional<std::vector<double>>(j, "speed"));
        x.setVolume(MovieConsumer::get_optional<std::vector<double>>(j, "volume"));
        x.setStartTime(MovieConsumer::get_optional<std::vector<int64_t>>(j, "start_time"));
        x.setEndTime(MovieConsumer::get_optional<std::vector<int64_t>>(j, "end_time"));
        x.setVideoUrlList(MovieConsumer::get_optional<std::vector<std::string>>(j, "video_url_list"));
        x.setMusicVolume(MovieConsumer::get_optional<double>(j, "music_volume"));
        x.setLoopMusic(MovieConsumer::get_optional<bool>(j, "loop_music"));
    }

    inline void to_json(json & j, const MovieConsumer::MovieConfig & x) {
        j = json::object();
        j["frame_unify_bbox"] = x.getFrameUnifyBbox();
        j["music_url"] = x.getMusicUrl();
        j["gen_pure_ate_video"] = x.getGenPureAteVideo();
        j["gen_cm_ate_video"] = x.getGenCmAteVideo();
        j["img_ATEs"] = x.getImgAtEs();
        j["CM_ATEs"] = x.getCmAtEs();
        j["material_type"] = x.getMaterialType();
        j["metas"] = x.getMetas();
        j["img_time_stamps"] = x.getImgTimeStamps();
        j["cm_start_bboxs"] = x.getCmStartBboxs();
        j["cm_end_bboxs"] = x.getCmEndBboxs();
        j["music_fade_in_out_dur"] = x.getMusicFadeInOutDur();
        j["music_lyrics"] = x.getMusicLyrics();
        j["lyrics_styles"] = x.getLyricsStyles();
        j["speed"] = x.getSpeed();
        j["volume"] = x.getVolume();
        j["start_time"] = x.getStartTime();
        j["end_time"] = x.getEndTime();
        j["video_url_list"] = x.getVideoUrlList();
        j["music_volume"] = x.getMusicVolume();
        j["loop_music"] = x.getLoopMusic();
    }
    inline void from_json(const json & j, MovieConsumer::Variant & x) {
        if (j.is_number_integer())
            x = j.get<int64_t>();
        else if (j.is_string())
            x = j.get<std::string>();
        else if (j.is_number_float())
            x = j.get<float>();
        else throw "Could not deserialize";
    }

    inline void to_json(json & j, const MovieConsumer::Variant & x) {
        if (x.isInt()) {
            j = x.intValue;
        } else if (x.isFloat()) {
            j = x.fValue;
        } else {
            j = x.strValue;
        }
    }
}
