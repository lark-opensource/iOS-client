//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class CoverTemplate {
        public:
        CoverTemplate();
        virtual ~CoverTemplate();

        private:
        std::string cover_template_category;
        std::string cover_template_category_id;
        std::string cover_template_id;
        std::vector<std::string> cover_template_material_ids;

        public:
        const std::string & get_cover_template_category() const;
        std::string & get_mut_cover_template_category();
        void set_cover_template_category(const std::string & value) ;

        const std::string & get_cover_template_category_id() const;
        std::string & get_mut_cover_template_category_id();
        void set_cover_template_category_id(const std::string & value) ;

        const std::string & get_cover_template_id() const;
        std::string & get_mut_cover_template_id();
        void set_cover_template_id(const std::string & value) ;

        const std::vector<std::string> & get_cover_template_material_ids() const;
        std::vector<std::string> & get_mut_cover_template_material_ids();
        void set_cover_template_material_ids(const std::vector<std::string> & value) ;
    };
}
