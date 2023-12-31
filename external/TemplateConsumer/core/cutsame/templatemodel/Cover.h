//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include "CoverType.h"

namespace CutSame {
    class CoverDraft;
    class CoverTemplate;
    class CoverFrameInfo;
    class CoverImageInfo;
    class CoverMaterials;
}

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class Cover {
        public:
        Cover();
        virtual ~Cover();

        private:
        std::shared_ptr<CoverDraft> cover_draft;
        std::shared_ptr<CoverTemplate> cover_template;
        std::shared_ptr<CoverFrameInfo> frame_info;
        std::shared_ptr<CoverImageInfo> image_info;
        std::shared_ptr<CoverMaterials> materials;
        CoverType type;

        public:
        const std::shared_ptr<CoverDraft> & get_cover_draft() const;
        std::shared_ptr<CoverDraft> & get_mut_cover_draft();
        void set_cover_draft(const std::shared_ptr<CoverDraft> & value) ;

        const std::shared_ptr<CoverTemplate> & get_cover_template() const;
        std::shared_ptr<CoverTemplate> & get_mut_cover_template();
        void set_cover_template(const std::shared_ptr<CoverTemplate> & value) ;

        const std::shared_ptr<CoverFrameInfo> & get_frame_info() const;
        std::shared_ptr<CoverFrameInfo> & get_mut_frame_info();
        void set_frame_info(const std::shared_ptr<CoverFrameInfo> & value) ;

        const std::shared_ptr<CoverImageInfo> & get_image_info() const;
        std::shared_ptr<CoverImageInfo> & get_mut_image_info();
        void set_image_info(const std::shared_ptr<CoverImageInfo> & value) ;

        const std::shared_ptr<CoverMaterials> & get_materials() const;
        std::shared_ptr<CoverMaterials> & get_mut_materials();
        void set_materials(const std::shared_ptr<CoverMaterials> & value) ;

        const CoverType & get_type() const;
        CoverType & get_mut_type();
        void set_type(const CoverType & value) ;
    };
}
