//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "Material.h"
namespace CutSame {
    class AiBeats;
    class UserDeleteAiBeats;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class MaterialBeat : public Material {
        public:
        MaterialBeat();
        virtual ~MaterialBeat();

        private:
        std::shared_ptr<AiBeats> ai_beats;
        bool enable_ai_beats;
        int64_t gear;
        int64_t mode;
        std::vector<int64_t> user_beats;
        std::shared_ptr<UserDeleteAiBeats> user_delete_ai_beats;

        public:
        const std::shared_ptr<AiBeats> & get_ai_beats() const;
        std::shared_ptr<AiBeats> & get_mut_ai_beats();
        void set_ai_beats(const std::shared_ptr<AiBeats> & value) ;

        const bool & get_enable_ai_beats() const;
        bool & get_mut_enable_ai_beats();
        void set_enable_ai_beats(const bool & value) ;

        const int64_t & get_gear() const;
        int64_t & get_mut_gear();
        void set_gear(const int64_t & value) ;

        const int64_t & get_mode() const;
        int64_t & get_mut_mode();
        void set_mode(const int64_t & value) ;

        const std::vector<int64_t> & get_user_beats() const;
        std::vector<int64_t> & get_mut_user_beats();
        void set_user_beats(const std::vector<int64_t> & value) ;

        const std::shared_ptr<UserDeleteAiBeats> & get_user_delete_ai_beats() const;
        std::shared_ptr<UserDeleteAiBeats> & get_mut_user_delete_ai_beats();
        void set_user_delete_ai_beats(const std::shared_ptr<UserDeleteAiBeats> & value) ;
    };
}
