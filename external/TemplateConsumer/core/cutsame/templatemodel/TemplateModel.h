//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class CanvasConfig;
    class Config;
    class Cover;
    class ExtraInfo;
    class Keyframes;
    class Materials;
    class MutableConfig;
    class PlatformClass;
    class RelationShip;
    class Track;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class TemplateModel {
        public:
        TemplateModel();
        virtual ~TemplateModel();

        private:
        std::shared_ptr<CanvasConfig> canvas_config;
        std::shared_ptr<Config> config;
        std::shared_ptr<Cover> cover;
        int64_t create_time;
        int64_t duration;
        std::shared_ptr<ExtraInfo> extra_info;
        std::string id;
        std::shared_ptr<Keyframes> keyframes;
        std::shared_ptr<Materials> materials;
        std::shared_ptr<MutableConfig> mutable_config;
        std::string name;
        std::string new_version;
        std::shared_ptr<PlatformClass> platform;
        std::vector<std::shared_ptr<RelationShip>> relationships;
        std::vector<std::shared_ptr<Track>> tracks;
        int64_t update_time;
        int64_t version;
        std::string workspace;

        public:
        const std::shared_ptr<CanvasConfig> & get_canvas_config() const;
        std::shared_ptr<CanvasConfig> & get_mut_canvas_config();
        void set_canvas_config(const std::shared_ptr<CanvasConfig> & value) ;

        const std::shared_ptr<Config> & get_config() const;
        std::shared_ptr<Config> & get_mut_config();
        void set_config(const std::shared_ptr<Config> & value) ;

        const std::shared_ptr<Cover> & get_cover() const;
        std::shared_ptr<Cover> & get_mut_cover();
        void set_cover(const std::shared_ptr<Cover> & value) ;

        const int64_t & get_create_time() const;
        int64_t & get_mut_create_time();
        void set_create_time(const int64_t & value) ;

        const int64_t & get_duration() const;
        int64_t & get_mut_duration();
        void set_duration(const int64_t & value) ;

        const std::shared_ptr<ExtraInfo> & get_extra_info() const;
        std::shared_ptr<ExtraInfo> & get_mut_extra_info();
        void set_extra_info(const std::shared_ptr<ExtraInfo> & value) ;

        const std::string & get_id() const;
        std::string & get_mut_id();
        void set_id(const std::string & value) ;

        const std::shared_ptr<Keyframes> & get_keyframes() const;
        std::shared_ptr<Keyframes> & get_mut_keyframes();
        void set_keyframes(const std::shared_ptr<Keyframes> & value) ;

        const std::shared_ptr<Materials> & get_materials() const;
        std::shared_ptr<Materials> & get_mut_materials();
        void set_materials(const std::shared_ptr<Materials> & value) ;

        const std::shared_ptr<MutableConfig> & get_mutable_config() const;
        std::shared_ptr<MutableConfig> & get_mut_mutable_config();
        void set_mutable_config(const std::shared_ptr<MutableConfig> & value) ;

        const std::string & get_name() const;
        std::string & get_mut_name();
        void set_name(const std::string & value) ;

        const std::string & get_new_version() const;
        std::string & get_mut_new_version();
        void set_new_version(const std::string & value) ;

        const std::shared_ptr<PlatformClass> & get_platform() const;
        std::shared_ptr<PlatformClass> & get_mut_platform();
        void set_platform(const std::shared_ptr<PlatformClass> & value) ;

        const std::vector<std::shared_ptr<RelationShip>> & get_relationships() const;
        std::vector<std::shared_ptr<RelationShip>> & get_mut_relationships();
        void set_relationships(const std::vector<std::shared_ptr<RelationShip>> & value) ;

        const std::vector<std::shared_ptr<Track>> & get_tracks() const;
        std::vector<std::shared_ptr<Track>> & get_mut_tracks();
        void set_tracks(const std::vector<std::shared_ptr<Track>> & value) ;

        const int64_t & get_update_time() const;
        int64_t & get_mut_update_time();
        void set_update_time(const int64_t & value) ;

        const int64_t & get_version() const;
        int64_t & get_mut_version();
        void set_version(const int64_t & value) ;

        const std::string & get_workspace() const;
        std::string & get_mut_workspace();
        void set_workspace(const std::string & value) ;
    };
}
