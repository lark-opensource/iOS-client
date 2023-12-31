//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Config {
        public:
        Config();
        virtual ~Config();

        private:
        int64_t adjust_max_index;
        int64_t extract_audio_last_index;
        std::string lyrics_recognition_id;
        bool lyrics_sync;
        int64_t original_sound_last_index;
        int64_t record_audio_last_index;
        int64_t sticker_max_index;
        std::string subtitle_recognition_id;
        bool subtitle_sync;
        bool video_mute;

        public:
        const int64_t & get_adjust_max_index() const;
        int64_t & get_mut_adjust_max_index();
        void set_adjust_max_index(const int64_t & value) ;

        const int64_t & get_extract_audio_last_index() const;
        int64_t & get_mut_extract_audio_last_index();
        void set_extract_audio_last_index(const int64_t & value) ;

        const std::string & get_lyrics_recognition_id() const;
        std::string & get_mut_lyrics_recognition_id();
        void set_lyrics_recognition_id(const std::string & value) ;

        const bool & get_lyrics_sync() const;
        bool & get_mut_lyrics_sync();
        void set_lyrics_sync(const bool & value) ;

        const int64_t & get_original_sound_last_index() const;
        int64_t & get_mut_original_sound_last_index();
        void set_original_sound_last_index(const int64_t & value) ;

        const int64_t & get_record_audio_last_index() const;
        int64_t & get_mut_record_audio_last_index();
        void set_record_audio_last_index(const int64_t & value) ;

        const int64_t & get_sticker_max_index() const;
        int64_t & get_mut_sticker_max_index();
        void set_sticker_max_index(const int64_t & value) ;

        const std::string & get_subtitle_recognition_id() const;
        std::string & get_mut_subtitle_recognition_id();
        void set_subtitle_recognition_id(const std::string & value) ;

        const bool & get_subtitle_sync() const;
        bool & get_mut_subtitle_sync();
        void set_subtitle_sync(const bool & value) ;

        const bool & get_video_mute() const;
        bool & get_mut_video_mute();
        void set_video_mute(const bool & value) ;
    };
}
