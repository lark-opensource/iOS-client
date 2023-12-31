//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class Crop;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class CoverImageInfo {
        public:
        CoverImageInfo();
        virtual ~CoverImageInfo();

        private:
        std::shared_ptr<Crop> crop;
        std::string path;

        public:
        const std::shared_ptr<Crop> & get_crop() const;
        std::shared_ptr<Crop> & get_mut_crop();
        void set_crop(const std::shared_ptr<Crop> & value) ;

        const std::string & get_path() const;
        std::string & get_mut_path();
        void set_path(const std::string & value) ;
    };
}
