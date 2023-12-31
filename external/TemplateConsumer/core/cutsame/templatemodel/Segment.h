//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class Clip;
    class Material;
    class Keyframe;
    class Timerange;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Segment {
        public:
        Segment();
        virtual ~Segment();

        private:
        double avg_speed;
        bool cartoon;
        std::shared_ptr<Clip> clip;
        std::vector<std::string> extra_material_refs;
        std::vector<std::shared_ptr<Material>> extra_materials;
        std::string id;
        bool intensifies_audio;
        bool is_tone_modify;
        std::vector<std::string> keyframe_refs;
        std::vector<std::shared_ptr<Keyframe>> keyframes;
        double last_nonzero_volume;
        std::shared_ptr<Material> main_material;
        std::string material_id;
        bool mirror;
        int64_t render_index;
        bool reverse;
        std::shared_ptr<Timerange> source_timerange;
        double speed;
        std::shared_ptr<Timerange> target_timerange;
        int64_t target_time_offset;
        double volume;

        public:
        const double & get_avg_speed() const;
        double & get_mut_avg_speed();
        void set_avg_speed(const double & value) ;

        const bool & get_cartoon() const;
        bool & get_mut_cartoon();
        void set_cartoon(const bool & value) ;

        const std::shared_ptr<Clip> & get_clip() const;
        std::shared_ptr<Clip> & get_mut_clip();
        void set_clip(const std::shared_ptr<Clip> & value) ;

        const std::vector<std::string> & get_extra_material_refs() const;
        std::vector<std::string> & get_mut_extra_material_refs();
        void set_extra_material_refs(const std::vector<std::string> & value) ;

        const std::vector<std::shared_ptr<Material>> & get_extra_materials() const;
        std::vector<std::shared_ptr<Material>> & get_mut_extra_materials();
        void set_extra_materials(const std::vector<std::shared_ptr<Material>> & value) ;

        const std::string & get_id() const;
        std::string & get_mut_id();
        void set_id(const std::string & value) ;

        const bool & get_intensifies_audio() const;
        bool & get_mut_intensifies_audio();
        void set_intensifies_audio(const bool & value) ;

        const bool & get_is_tone_modify() const;
        bool & get_mut_is_tone_modify();
        void set_is_tone_modify(const bool & value) ;

        const std::vector<std::string> & get_keyframe_refs() const;
        std::vector<std::string> & get_mut_keyframe_refs();
        void set_keyframe_refs(const std::vector<std::string> & value) ;

        const std::vector<std::shared_ptr<Keyframe>> & get_keyframes() const;
        std::vector<std::shared_ptr<Keyframe>> & get_mut_keyframes();
        void set_keyframes(const std::vector<std::shared_ptr<Keyframe>> & value) ;

        const double & get_last_nonzero_volume() const;
        double & get_mut_last_nonzero_volume();
        void set_last_nonzero_volume(const double & value) ;

        const std::shared_ptr<Material> & get_main_material() const;
        std::shared_ptr<Material> & get_mut_main_material();
        void set_main_material(const std::shared_ptr<Material> & value) ;

        const std::string & get_material_id() const;
        std::string & get_mut_material_id();
        void set_material_id(const std::string & value) ;

        const bool & get_mirror() const;
        bool & get_mut_mirror();
        void set_mirror(const bool & value) ;

        const int64_t & get_render_index() const;
        int64_t & get_mut_render_index();
        void set_render_index(const int64_t & value) ;

        const bool & get_reverse() const;
        bool & get_mut_reverse();
        void set_reverse(const bool & value) ;

        const std::shared_ptr<Timerange> & get_source_timerange() const;
        std::shared_ptr<Timerange> & get_mut_source_timerange();
        void set_source_timerange(const std::shared_ptr<Timerange> & value) ;

        const double & get_speed() const;
        double & get_mut_speed();
        void set_speed(const double & value) ;

        const std::shared_ptr<Timerange> & get_target_timerange() const;
        std::shared_ptr<Timerange> & get_mut_target_timerange();
        void set_target_timerange(const std::shared_ptr<Timerange> & value) ;

        const int64_t & get_target_time_offset() const;
        int64_t & get_mut_target_time_offset();
        void set_target_time_offset(const int64_t & value) ;

        const double & get_volume() const;
        double & get_mut_volume();
        void set_volume(const double & value) ;
    };
}
