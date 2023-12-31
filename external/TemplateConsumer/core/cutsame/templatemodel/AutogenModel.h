//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class DependencyResource;
    class EffectTemplate;
    class Keyframe;
    class Material;
    class TailSegment;
    class TemplateModel;
    class TemplateParam;
    class TextSegment;
    class TimeClipParam;
    class VeConfig;
    class VideoCompileParam;
    class VideoPreviewConfig;
    class VideoSegment;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class AutogenModel {
        public:
        AutogenModel();
        virtual ~AutogenModel();

        private:
        std::shared_ptr<DependencyResource> dependency_resource;
        std::shared_ptr<EffectTemplate> effect_template;
        std::shared_ptr<Keyframe> keyframe;
        std::shared_ptr<Material> material;
        std::shared_ptr<TailSegment> tail_segment;
        std::shared_ptr<TemplateModel> template_model;
        std::shared_ptr<TemplateParam> template_param;
        std::shared_ptr<TextSegment> text_segment;
        std::shared_ptr<TimeClipParam> time_clip_param;
        std::shared_ptr<VeConfig> ve_config;
        std::shared_ptr<VideoCompileParam> video_compile_param;
        std::shared_ptr<VideoPreviewConfig> video_preview_config;
        std::shared_ptr<VideoSegment> video_segment;

        public:
        const std::shared_ptr<DependencyResource> & get_dependency_resource() const;
        std::shared_ptr<DependencyResource> & get_mut_dependency_resource();
        void set_dependency_resource(const std::shared_ptr<DependencyResource> & value) ;

        const std::shared_ptr<EffectTemplate> & get_effect_template() const;
        std::shared_ptr<EffectTemplate> & get_mut_effect_template();
        void set_effect_template(const std::shared_ptr<EffectTemplate> & value) ;

        const std::shared_ptr<Keyframe> & get_keyframe() const;
        std::shared_ptr<Keyframe> & get_mut_keyframe();
        void set_keyframe(const std::shared_ptr<Keyframe> & value) ;

        const std::shared_ptr<Material> & get_material() const;
        std::shared_ptr<Material> & get_mut_material();
        void set_material(const std::shared_ptr<Material> & value) ;

        const std::shared_ptr<TailSegment> & get_tail_segment() const;
        std::shared_ptr<TailSegment> & get_mut_tail_segment();
        void set_tail_segment(const std::shared_ptr<TailSegment> & value) ;

        const std::shared_ptr<TemplateModel> & get_template_model() const;
        std::shared_ptr<TemplateModel> & get_mut_template_model();
        void set_template_model(const std::shared_ptr<TemplateModel> & value) ;

        const std::shared_ptr<TemplateParam> & get_template_param() const;
        std::shared_ptr<TemplateParam> & get_mut_template_param();
        void set_template_param(const std::shared_ptr<TemplateParam> & value) ;

        const std::shared_ptr<TextSegment> & get_text_segment() const;
        std::shared_ptr<TextSegment> & get_mut_text_segment();
        void set_text_segment(const std::shared_ptr<TextSegment> & value) ;

        const std::shared_ptr<TimeClipParam> & get_time_clip_param() const;
        std::shared_ptr<TimeClipParam> & get_mut_time_clip_param();
        void set_time_clip_param(const std::shared_ptr<TimeClipParam> & value) ;

        const std::shared_ptr<VeConfig> & get_ve_config() const;
        std::shared_ptr<VeConfig> & get_mut_ve_config();
        void set_ve_config(const std::shared_ptr<VeConfig> & value) ;

        const std::shared_ptr<VideoCompileParam> & get_video_compile_param() const;
        std::shared_ptr<VideoCompileParam> & get_mut_video_compile_param();
        void set_video_compile_param(const std::shared_ptr<VideoCompileParam> & value) ;

        const std::shared_ptr<VideoPreviewConfig> & get_video_preview_config() const;
        std::shared_ptr<VideoPreviewConfig> & get_mut_video_preview_config();
        void set_video_preview_config(const std::shared_ptr<VideoPreviewConfig> & value) ;

        const std::shared_ptr<VideoSegment> & get_video_segment() const;
        std::shared_ptr<VideoSegment> & get_mut_video_segment();
        void set_video_segment(const std::shared_ptr<VideoSegment> & value) ;
    };
}
