//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class AdjustKeyframe;
    class AudioKeyframe;
    class FilterKeyframe;
    class StickerKeyframe;
    class TextKeyframe;
    class VideoKeyframe;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Keyframes {
        public:
        Keyframes();
        virtual ~Keyframes();

        private:
        std::vector<std::shared_ptr<AdjustKeyframe>> adjusts;
        std::vector<std::shared_ptr<AudioKeyframe>> audios;
        std::vector<std::shared_ptr<FilterKeyframe>> filters;
        std::vector<std::shared_ptr<StickerKeyframe>> stickers;
        std::vector<std::shared_ptr<TextKeyframe>> texts;
        std::vector<std::shared_ptr<VideoKeyframe>> videos;

        public:
        const std::vector<std::shared_ptr<AdjustKeyframe>> & get_adjusts() const;
        std::vector<std::shared_ptr<AdjustKeyframe>> & get_mut_adjusts();
        void set_adjusts(const std::vector<std::shared_ptr<AdjustKeyframe>> & value) ;

        const std::vector<std::shared_ptr<AudioKeyframe>> & get_audios() const;
        std::vector<std::shared_ptr<AudioKeyframe>> & get_mut_audios();
        void set_audios(const std::vector<std::shared_ptr<AudioKeyframe>> & value) ;

        const std::vector<std::shared_ptr<FilterKeyframe>> & get_filters() const;
        std::vector<std::shared_ptr<FilterKeyframe>> & get_mut_filters();
        void set_filters(const std::vector<std::shared_ptr<FilterKeyframe>> & value) ;

        const std::vector<std::shared_ptr<StickerKeyframe>> & get_stickers() const;
        std::vector<std::shared_ptr<StickerKeyframe>> & get_mut_stickers();
        void set_stickers(const std::vector<std::shared_ptr<StickerKeyframe>> & value) ;

        const std::vector<std::shared_ptr<TextKeyframe>> & get_texts() const;
        std::vector<std::shared_ptr<TextKeyframe>> & get_mut_texts();
        void set_texts(const std::vector<std::shared_ptr<TextKeyframe>> & value) ;

        const std::vector<std::shared_ptr<VideoKeyframe>> & get_videos() const;
        std::vector<std::shared_ptr<VideoKeyframe>> & get_mut_videos();
        void set_videos(const std::vector<std::shared_ptr<VideoKeyframe>> & value) ;
    };
}
