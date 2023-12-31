//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class MaterialAudioEffect;
    class MaterialAudioFade;
    class MaterialAudio;
    class MaterialBeat;
    class MaterialCanvas;
    class MaterialChroma;
    class MaterialEffect;
    class MaterialImage;
    class MaterialMask;
    class Animations;
    class MaterialPlaceholder;
    class RealtimeDenoises;
    class MaterialSpeed;
    class MaterialSticker;
    class MaterialTailLeader;
    class MaterialTextTemplate;
    class MaterialText;
    class MaterialTransition;
    class MaterialVideo;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Materials {
        public:
        Materials();
        virtual ~Materials();

        private:
        std::vector<std::shared_ptr<MaterialAudioEffect>> audio_effects;
        std::vector<std::shared_ptr<MaterialAudioFade>> audio_fades;
        std::vector<std::shared_ptr<MaterialAudio>> audios;
        std::vector<std::shared_ptr<MaterialBeat>> beats;
        std::vector<std::shared_ptr<MaterialCanvas>> canvases;
        std::vector<std::shared_ptr<MaterialChroma>> chromas;
        std::vector<std::shared_ptr<MaterialEffect>> effects;
        std::vector<std::shared_ptr<MaterialImage>> images;
        std::vector<std::shared_ptr<MaterialMask>> masks;
        std::vector<std::shared_ptr<Animations>> material_animations;
        std::vector<std::shared_ptr<MaterialPlaceholder>> placeholders;
        std::vector<std::shared_ptr<RealtimeDenoises>> realtime_denoises;
        std::vector<std::shared_ptr<MaterialSpeed>> speeds;
        std::vector<std::shared_ptr<MaterialSticker>> stickers;
        std::vector<std::shared_ptr<MaterialTailLeader>> tail_leaders;
        std::vector<std::shared_ptr<MaterialTextTemplate>> text_templates;
        std::vector<std::shared_ptr<MaterialText>> texts;
        std::vector<std::shared_ptr<MaterialTransition>> transitions;
        std::vector<std::shared_ptr<MaterialVideo>> videos;

        public:
        const std::vector<std::shared_ptr<MaterialAudioEffect>> & get_audio_effects() const;
        std::vector<std::shared_ptr<MaterialAudioEffect>> & get_mut_audio_effects();
        void set_audio_effects(const std::vector<std::shared_ptr<MaterialAudioEffect>> & value) ;

        const std::vector<std::shared_ptr<MaterialAudioFade>> & get_audio_fades() const;
        std::vector<std::shared_ptr<MaterialAudioFade>> & get_mut_audio_fades();
        void set_audio_fades(const std::vector<std::shared_ptr<MaterialAudioFade>> & value) ;

        const std::vector<std::shared_ptr<MaterialAudio>> & get_audios() const;
        std::vector<std::shared_ptr<MaterialAudio>> & get_mut_audios();
        void set_audios(const std::vector<std::shared_ptr<MaterialAudio>> & value) ;

        const std::vector<std::shared_ptr<MaterialBeat>> & get_beats() const;
        std::vector<std::shared_ptr<MaterialBeat>> & get_mut_beats();
        void set_beats(const std::vector<std::shared_ptr<MaterialBeat>> & value) ;

        const std::vector<std::shared_ptr<MaterialCanvas>> & get_canvases() const;
        std::vector<std::shared_ptr<MaterialCanvas>> & get_mut_canvases();
        void set_canvases(const std::vector<std::shared_ptr<MaterialCanvas>> & value) ;

        const std::vector<std::shared_ptr<MaterialChroma>> & get_chromas() const;
        std::vector<std::shared_ptr<MaterialChroma>> & get_mut_chromas();
        void set_chromas(const std::vector<std::shared_ptr<MaterialChroma>> & value) ;

        const std::vector<std::shared_ptr<MaterialEffect>> & get_effects() const;
        std::vector<std::shared_ptr<MaterialEffect>> & get_mut_effects();
        void set_effects(const std::vector<std::shared_ptr<MaterialEffect>> & value) ;

        const std::vector<std::shared_ptr<MaterialImage>> & get_images() const;
        std::vector<std::shared_ptr<MaterialImage>> & get_mut_images();
        void set_images(const std::vector<std::shared_ptr<MaterialImage>> & value) ;

        const std::vector<std::shared_ptr<MaterialMask>> & get_masks() const;
        std::vector<std::shared_ptr<MaterialMask>> & get_mut_masks();
        void set_masks(const std::vector<std::shared_ptr<MaterialMask>> & value) ;

        const std::vector<std::shared_ptr<Animations>> & get_material_animations() const;
        std::vector<std::shared_ptr<Animations>> & get_mut_material_animations();
        void set_material_animations(const std::vector<std::shared_ptr<Animations>> & value) ;

        const std::vector<std::shared_ptr<MaterialPlaceholder>> & get_placeholders() const;
        std::vector<std::shared_ptr<MaterialPlaceholder>> & get_mut_placeholders();
        void set_placeholders(const std::vector<std::shared_ptr<MaterialPlaceholder>> & value) ;

        const std::vector<std::shared_ptr<RealtimeDenoises>> & get_realtime_denoises() const;
        std::vector<std::shared_ptr<RealtimeDenoises>> & get_mut_realtime_denoises();
        void set_realtime_denoises(const std::vector<std::shared_ptr<RealtimeDenoises>> & value) ;

        const std::vector<std::shared_ptr<MaterialSpeed>> & get_speeds() const;
        std::vector<std::shared_ptr<MaterialSpeed>> & get_mut_speeds();
        void set_speeds(const std::vector<std::shared_ptr<MaterialSpeed>> & value) ;

        const std::vector<std::shared_ptr<MaterialSticker>> & get_stickers() const;
        std::vector<std::shared_ptr<MaterialSticker>> & get_mut_stickers();
        void set_stickers(const std::vector<std::shared_ptr<MaterialSticker>> & value) ;

        const std::vector<std::shared_ptr<MaterialTailLeader>> & get_tail_leaders() const;
        std::vector<std::shared_ptr<MaterialTailLeader>> & get_mut_tail_leaders();
        void set_tail_leaders(const std::vector<std::shared_ptr<MaterialTailLeader>> & value) ;

        const std::vector<std::shared_ptr<MaterialTextTemplate>> & get_text_templates() const;
        std::vector<std::shared_ptr<MaterialTextTemplate>> & get_mut_text_templates();
        void set_text_templates(const std::vector<std::shared_ptr<MaterialTextTemplate>> & value) ;

        const std::vector<std::shared_ptr<MaterialText>> & get_texts() const;
        std::vector<std::shared_ptr<MaterialText>> & get_mut_texts();
        void set_texts(const std::vector<std::shared_ptr<MaterialText>> & value) ;

        const std::vector<std::shared_ptr<MaterialTransition>> & get_transitions() const;
        std::vector<std::shared_ptr<MaterialTransition>> & get_mut_transitions();
        void set_transitions(const std::vector<std::shared_ptr<MaterialTransition>> & value) ;

        const std::vector<std::shared_ptr<MaterialVideo>> & get_videos() const;
        std::vector<std::shared_ptr<MaterialVideo>> & get_mut_videos();
        void set_videos(const std::vector<std::shared_ptr<MaterialVideo>> & value) ;
    };
}
