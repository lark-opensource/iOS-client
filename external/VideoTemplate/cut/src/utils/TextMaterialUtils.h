//
//  TextMaterialUtils.hpp
//  LVTemplate
//
//  Created by ZhangYuanming on 2020/2/14.
//

#ifndef TextMaterialUtils_hpp
#define TextMaterialUtils_hpp

#include <stdio.h>
#include <TemplateConsumer/MaterialText.h>

namespace cut {


struct TextMaterialUtils {
    const static std::string DEFAULT_SHADOW_COLOR();
    const static int DEFAULT_TEXT_SIZE();

    const static int ALIGN_LEFT();
    const static int ALIGN_CENTER();
    const static int ALIGN_RIGHT();
    const static int ALIGN_UP();
    const static int ALIGN_DOWN();
    
    
    static CutSame::MaterialText genEpilogueMaterial(const std::string &text, const std::string &textFont);
};


}

#endif /* TextMaterialUtils_hpp */
