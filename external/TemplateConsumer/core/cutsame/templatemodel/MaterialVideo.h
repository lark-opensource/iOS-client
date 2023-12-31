//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"
#include "CropRatio.h"

namespace CutSame {
    class Crop;
    class GamePlay;
    class TypePathInfo;
    class Stable;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialVideo : public Material {
        public:
        MaterialVideo();
        virtual ~MaterialVideo();

        private:
        int64_t ai_matting;
        std::string cartoon_path;
        std::string category_id;
        std::string category_name;
        std::shared_ptr<Crop> crop;
        CropRatio crop_ratio;
        double crop_scale;
        int64_t duration;
        int64_t extra_type_option;
        std::shared_ptr<GamePlay> gameplay;
        std::string gameplay_algorithm;
        std::string gameplay_path;
        int64_t height;
        std::string intensifies_audio_path;
        std::string intensifies_path;
        std::string material_id;
        std::string material_name;
        std::string material_url;
        std::string path;
        std::vector<std::shared_ptr<TypePathInfo>> paths;
        std::string reverse_intensifies_path;
        std::string reverse_path;
        std::shared_ptr<Stable> stable;
        std::vector<int64_t> type_option;
        double volume;
        int64_t width;

        public:
        const int64_t & get_ai_matting() const;
        int64_t & get_mut_ai_matting();
        void set_ai_matting(const int64_t & value) ;

        const std::string & get_cartoon_path() const;
        std::string & get_mut_cartoon_path();
        void set_cartoon_path(const std::string & value) ;

        const std::string & get_category_id() const;
        std::string & get_mut_category_id();
        void set_category_id(const std::string & value) ;

        const std::string & get_category_name() const;
        std::string & get_mut_category_name();
        void set_category_name(const std::string & value) ;

        const std::shared_ptr<Crop> & get_crop() const;
        std::shared_ptr<Crop> & get_mut_crop();
        void set_crop(const std::shared_ptr<Crop> & value) ;

        const CropRatio & get_crop_ratio() const;
        CropRatio & get_mut_crop_ratio();
        void set_crop_ratio(const CropRatio & value) ;

        const double & get_crop_scale() const;
        double & get_mut_crop_scale();
        void set_crop_scale(const double & value) ;

        const int64_t & get_duration() const;
        int64_t & get_mut_duration();
        void set_duration(const int64_t & value) ;

        const int64_t & get_extra_type_option() const;
        int64_t & get_mut_extra_type_option();
        void set_extra_type_option(const int64_t & value) ;

        const std::shared_ptr<GamePlay> & get_gameplay() const;
        std::shared_ptr<GamePlay> & get_mut_gameplay();
        void set_gameplay(const std::shared_ptr<GamePlay> & value) ;

        const std::string & get_gameplay_algorithm() const;
        std::string & get_mut_gameplay_algorithm();
        void set_gameplay_algorithm(const std::string & value) ;

        const std::string & get_gameplay_path() const;
        std::string & get_mut_gameplay_path();
        void set_gameplay_path(const std::string & value) ;

        const int64_t & get_height() const;
        int64_t & get_mut_height();
        void set_height(const int64_t & value) ;

        const std::string & get_intensifies_audio_path() const;
        std::string & get_mut_intensifies_audio_path();
        void set_intensifies_audio_path(const std::string & value) ;

        const std::string & get_intensifies_path() const;
        std::string & get_mut_intensifies_path();
        void set_intensifies_path(const std::string & value) ;

        const std::string & get_material_id() const;
        std::string & get_mut_material_id();
        void set_material_id(const std::string & value) ;

        const std::string & get_material_name() const;
        std::string & get_mut_material_name();
        void set_material_name(const std::string & value) ;

        const std::string & get_material_url() const;
        std::string & get_mut_material_url();
        void set_material_url(const std::string & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const std::vector<std::shared_ptr<TypePathInfo>> & get_paths() const;
        std::vector<std::shared_ptr<TypePathInfo>> & get_mut_paths();
        void set_paths(const std::vector<std::shared_ptr<TypePathInfo>> & value) ;

        const std::string & get_reverse_intensifies_path() const;
        std::string & get_mut_reverse_intensifies_path();
        void set_reverse_intensifies_path(const std::string & value) ;

        const std::string & get_reverse_path() const;
        std::string & get_mut_reverse_path();
        void set_reverse_path(const std::string & value) ;

        const std::shared_ptr<Stable> & get_stable() const;
        std::shared_ptr<Stable> & get_mut_stable();
        void set_stable(const std::shared_ptr<Stable> & value) ;

        const std::vector<int64_t> & get_type_option() const;
        std::vector<int64_t> & get_mut_type_option();
        void set_type_option(const std::vector<int64_t> & value) ;

        const double & get_volume() const;
        double & get_mut_volume();
        void set_volume(const double & value) ;

        const int64_t & get_width() const;
        int64_t & get_mut_width();
        void set_width(const int64_t & value) ;
    };
}
