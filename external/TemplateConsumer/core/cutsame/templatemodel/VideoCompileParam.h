//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class VideoCompileParam {
        public:
        VideoCompileParam();
        virtual ~VideoCompileParam();

        private:
        std::string audio_file_path;
        int64_t bps;
        std::string compile_json_str;
        std::string encode_profile;
        int64_t fps;
        int64_t gop_size;
        int64_t height;
        bool is_audio_only;
        bool support_hw_encoder;
        int64_t width;

        public:
        const std::string & get_audio_file_path() const;
        std::string & get_mut_audio_file_path();
        void set_audio_file_path(const std::string & value) ;

        const int64_t & get_bps() const;
        int64_t & get_mut_bps();
        void set_bps(const int64_t & value) ;

        const std::string & get_compile_json_str() const;
        std::string & get_mut_compile_json_str();
        void set_compile_json_str(const std::string & value) ;

        const std::string & get_encode_profile() const;
        std::string & get_mut_encode_profile();
        void set_encode_profile(const std::string & value) ;

        const int64_t & get_fps() const;
        int64_t & get_mut_fps();
        void set_fps(const int64_t & value) ;

        const int64_t & get_gop_size() const;
        int64_t & get_mut_gop_size();
        void set_gop_size(const int64_t & value) ;

        const int64_t & get_height() const;
        int64_t & get_mut_height();
        void set_height(const int64_t & value) ;

        const bool & get_is_audio_only() const;
        bool & get_mut_is_audio_only();
        void set_is_audio_only(const bool & value) ;

        const bool & get_support_hw_encoder() const;
        bool & get_mut_support_hw_encoder();
        void set_support_hw_encoder(const bool & value) ;

        const int64_t & get_width() const;
        int64_t & get_mut_width();
        void set_width(const int64_t & value) ;
    };
}
