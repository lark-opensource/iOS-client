//
// Created by Steven on 2021/1/22.
//
#pragma once

#ifndef TEMPLATECONSUMERAPP_MATERIALMIDDLEWARE_H
#define TEMPLATECONSUMERAPP_MATERIALMIDDLEWARE_H

#include <vector>
#include <string>
#include <memory>

namespace TemplateConsumer {
    class VideoMaterial {
    public:
        VideoMaterial();

        virtual ~VideoMaterial() = default;

    private:
        bool is_mutable;
        bool is_sub_video;
        bool is_reverse;
        float crop_scale;
        float crop_x_left;
        float crop_x_right;
        float crop_y_lower;
        float crop_y_upper;
        int32_t cartoon_type;
        int32_t width;
        int32_t height;
        int64_t source_start_time;
        int64_t target_start_time;
        int64_t duration;         // 经过转换后的素材duration，比如变速
        int64_t source_duration;  // 替换的素材需要的原始duration
        std::string material_id;
        std::string nle_slot_id;
        std::string align_mode;
        std::string path;
        std::string type; // video photo
        std::string origin_path;

    public:
        bool getIsMutable() const;

        bool getIsReverse() const;

        bool getIsSubVideo() const;

        float getCropScale() const;

        float getCropXLeft() const;

        float getCropXRight() const;

        float getCropYLower() const;

        float getCropYUpper() const;

        int32_t getCartoonType() const;

        int32_t getWidth() const;

        int32_t getHeight() const;

        int64_t getSourceStartTime() const;

        int64_t getTargetStartTime() const;

        int64_t getDuration() const;
        
        int64_t getSourceDuration() const;

        std::string getMaterialId() const;

        std::string getNLESlotId() const;

        std::string getAlignMode() const;

        std::string getPath() const;

        std::string getType() const;

        std::string getOriginPath() const;

        void setIsMutable(bool value);

        void setIsReverse(bool value);

        void setIsSubVideo(bool value);

        void setCropScale(float value);

        void setCropXLeft(float value);

        void setCropXRight(float value);

        void setCropYUpper(float value);

        void setCropYLower(float value);

        void setCartoonType(int32_t value);

        void setWidth(int32_t value);

        void setHeight(int32_t value);

        void setSourceStartTime(int64_t value);

        void setTargetStartTime(int64_t value);

        void setDuration(int64_t value);
        
        void setSourceDuration(int64_t value);

        void setMaterialId(const std::string &value);

        void setNLESlotId(const std::string &value);

        void setAlignMode(const std::string &value);

        void setPath(const std::string &value);

        void setType(const std::string &value);
        
        void setOriginPath(const std::string &value);
        
    };

    class TextMaterial {
    public:
        TextMaterial();

        virtual ~TextMaterial() = default;

    private:
        int64_t target_start_time;
        int64_t duration;
        bool is_mutable;
        float rotation;
        std::string material_id;
        std::string nle_slot_id;
        std::string text;

    public:
        int64_t getTargetStartTime() const;

        int64_t getDuration() const;

        bool getIsMutable() const;

        float getRotation() const;

        std::string getMaterialId() const;

        std::string getNLESlotId() const;

        std::string getText() const;


        void setTargetStartTime(int64_t value);

        void setDuration(int64_t value);

        void setIsMutable(bool value);

        void setRotation(float value);

        void setMaterialId(const std::string &value);

        void setNLESlotId(const std::string &value);

        void setText(const std::string &value);
    };
}

#endif //TEMPLATECONSUMERAPP_MATERIALMIDDLEWARE_H
