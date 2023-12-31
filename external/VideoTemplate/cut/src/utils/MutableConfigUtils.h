//
//  MutableConfigUtils.hpp
//  LVTemplate
//
//  Created by ZhangYuanming on 2020/2/14.
//

#ifndef MutableConfigUtils_hpp
#define MutableConfigUtils_hpp

#include <stdio.h>
#include <TemplateConsumer/MutableConfig.h>

namespace cut {

struct MutableConfigUtils {
    
    static bool isMutableMaterial(std::shared_ptr<CutSame::MutableConfig>mutableConfig, const std::string& id);
};



}

#endif /* MutableConfigUtils_hpp */
