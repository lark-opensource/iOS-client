//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class Clip;
    class Crop;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class VideoSegment {
        public:
        VideoSegment();
        virtual ~VideoSegment();

        private:
        int64_t ai_matting;
        std::string align_mode;
        std::string blend_path;
        int64_t cartoon_type;
        std::shared_ptr<Clip> clip;
        std::shared_ptr<Crop> crop;
        double crop_scale;
        int64_t duration;
        std::vector<std::string> frames;
        std::string gameplay_algorithm;
        int64_t height;
        std::string id;
        bool is_cartoon;
        bool is_mutable;
        bool is_reverse;
        bool is_sub_video;
        std::string material_id;
        std::string origin_path;
        std::string path;
        std::string relation_video_group;
        int64_t source_start_time;
        int64_t target_start_time;
        std::string type;
        double volume;
        int64_t width;

        public:
        const int64_t & get_ai_matting() const;
        int64_t & get_mut_ai_matting();
        void set_ai_matting(const int64_t & value) ;

        const std::string & get_align_mode() const;
        std::string & get_mut_align_mode();
        void set_align_mode(const std::string & value) ;

        const std::string & get_blend_path() const;
        std::string & get_mut_blend_path();
        void set_blend_path(const std::string & value) ;

        const int64_t & get_cartoon_type() const;
        int64_t & get_mut_cartoon_type();
        void set_cartoon_type(const int64_t & value) ;

        const std::shared_ptr<Clip> & get_clip() const;
        std::shared_ptr<Clip> & get_mut_clip();
        void set_clip(const std::shared_ptr<Clip> & value) ;

        const std::shared_ptr<Crop> & get_crop() const;
        std::shared_ptr<Crop> & get_mut_crop();
        void set_crop(const std::shared_ptr<Crop> & value) ;

        const double & get_crop_scale() const;
        double & get_mut_crop_scale();
        void set_crop_scale(const double & value) ;

        const int64_t & get_duration() const;
        int64_t & get_mut_duration();
        void set_duration(const int64_t & value) ;

        const std::vector<std::string> & get_frames() const;
        std::vector<std::string> & get_mut_frames();
        void set_frames(const std::vector<std::string> & value) ;

        const std::string & get_gameplay_algorithm() const;
        std::string & get_mut_gameplay_algorithm();
        void set_gameplay_algorithm(const std::string & value) ;

        const int64_t & get_height() const;
        int64_t & get_mut_height();
        void set_height(const int64_t & value) ;

        const std::string & get_id() const;
        std::string & get_mut_id();
        void set_id(const std::string & value) ;

        const bool & get_is_cartoon() const;
        bool & get_mut_is_cartoon();
        void set_is_cartoon(const bool & value) ;

        const bool & get_is_mutable() const;
        bool & get_mut_is_mutable();
        void set_is_mutable(const bool & value) ;

        const bool & get_is_reverse() const;
        bool & get_mut_is_reverse();
        void set_is_reverse(const bool & value) ;

        const bool & get_is_sub_video() const;
        bool & get_mut_is_sub_video();
        void set_is_sub_video(const bool & value) ;

        const std::string & get_material_id() const;
        std::string & get_mut_material_id();
        void set_material_id(const std::string & value) ;

        const std::string & get_origin_path() const;
        std::string & get_mut_origin_path();
        void set_origin_path(const std::string & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const std::string & get_relation_video_group() const;
        std::string & get_mut_relation_video_group();
        void set_relation_video_group(const std::string & value) ;

        const int64_t & get_source_start_time() const;
        int64_t & get_mut_source_start_time();
        void set_source_start_time(const int64_t & value) ;

        const int64_t & get_target_start_time() const;
        int64_t & get_mut_target_start_time();
        void set_target_start_time(const int64_t & value) ;

        const std::string & get_type() const;
        std::string & get_mut_type();
        void set_type(const std::string & value) ;

        const double & get_volume() const;
        double & get_mut_volume();
        void set_volume(const double & value) ;

        const int64_t & get_width() const;
        int64_t & get_mut_width();
        void set_width(const int64_t & value) ;
    };
}
