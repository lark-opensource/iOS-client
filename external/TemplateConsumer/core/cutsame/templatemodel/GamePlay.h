//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class GamePlay {
        public:
        GamePlay();
        virtual ~GamePlay();

        private:
        std::string algorithm;
        std::string path;
        bool reshape;

        public:
        const std::string & get_algorithm() const;
        std::string & get_mut_algorithm();
        void set_algorithm(const std::string & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;

        const bool & get_reshape() const;
        bool & get_mut_reshape();
        void set_reshape(const bool & value) ;
    };
}
