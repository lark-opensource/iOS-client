//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

namespace CutSame {
    class Segment;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Track {
        public:
        Track();
        virtual ~Track();

        private:
        int64_t flag;
        std::string id;
        std::vector<std::shared_ptr<Segment>> segments;
        std::string type;

        public:
        const int64_t & get_flag() const;
        int64_t & get_mut_flag();
        void set_flag(const int64_t & value) ;

        const std::string & get_id() const;
        std::string & get_mut_id();
        void set_id(const std::string & value) ;

        const std::vector<std::shared_ptr<Segment>> & get_segments() const;
        std::vector<std::shared_ptr<Segment>> & get_mut_segments();
        void set_segments(const std::vector<std::shared_ptr<Segment>> & value) ;

        const std::string & get_type() const;
        std::string & get_mut_type();
        void set_type(const std::string & value) ;
    };
}
