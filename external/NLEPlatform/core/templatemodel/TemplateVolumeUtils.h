//
//  TemplateVolumeUtils.hpp
//  NLEPlatform
//
//  Created by Lemonior on 2021/10/27.
//

#ifndef TemplateVolumeUtils_hpp
#define TemplateVolumeUtils_hpp

#include "NLETemplateModel.h"

namespace cut::model {
    class TemplateVolumeUtils {

    public:
        
        /**
         * 获取当前模板音乐是否可调节
         */
        static bool templateMutableItemVolumeEnable(std::shared_ptr<cut::model::NLETemplateModel> templateModel);
        /**
         * 更新模板音乐可调节状态
         */
        static void updateTemplateMutableItemVolumeEnableStatus(std::shared_ptr<cut::model::NLETemplateModel> templateModel, bool isEnabled);
    };
}

#endif /* TemplateVolumeUtils_hpp */
