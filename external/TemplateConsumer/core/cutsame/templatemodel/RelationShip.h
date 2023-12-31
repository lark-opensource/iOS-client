//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class RelationShip {
        public:
        RelationShip();
        virtual ~RelationShip();

        private:
        std::vector<std::string> id_to_id;
        std::string type;

        public:
        const std::vector<std::string> & get_id_to_id() const;
        std::vector<std::string> & get_mut_id_to_id();
        void set_id_to_id(const std::vector<std::string> & value) ;

        const std::string & get_type() const;
        std::string & get_mut_type();
        void set_type(const std::string & value) ;
    };
}
