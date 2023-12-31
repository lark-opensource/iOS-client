//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class AiBeats {
        public:
        AiBeats();
        virtual ~AiBeats();

        private:
        std::string beats_path;
        std::string beats_url;
        std::string melody_path;
        std::vector<double> melody_percents;
        std::string melody_url;

        public:
        const std::string & get_beats_path() const;
        std::string & get_mut_beats_path();
        void set_beats_path(const std::string & value) ;

        const std::string & get_beats_url() const;
        std::string & get_mut_beats_url();
        void set_beats_url(const std::string & value) ;

        const std::string & get_melody_path() const;
        std::string & get_mut_melody_path();
        void set_melody_path(const std::string & value) ;

        const std::vector<double> & get_melody_percents() const;
        std::vector<double> & get_mut_melody_percents();
        void set_melody_percents(const std::vector<double> & value) ;

        const std::string & get_melody_url() const;
        std::string & get_mut_melody_url();
        void set_melody_url(const std::string & value) ;
    };
}
