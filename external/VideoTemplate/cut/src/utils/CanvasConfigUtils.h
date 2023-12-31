//
//  CanvasConfigUtils.hpp
//  LVTemplate
//
//  Created by ZhangYuanming on 2020/2/15.
//

#ifndef CanvasConfigUtils_hpp
#define CanvasConfigUtils_hpp

#include <stdio.h>
#include <TemplateConsumer/CanvasConfig.h>
#include <map>

namespace cdom {

enum CanvasRatio {
    CanvasRatioOriginal = 0,
    CanvasRatioR16_9,
    CanvasRatioR9_16,
    CanvasRatioR4_3,
    CanvasRatioR3_4,
    CanvasRatioR1_1,
};

struct CanvasConfigUtils {
    
public:
    static std::map<std::string, cdom::CanvasRatio>* CanvasRotioTypeMapper();
    
    static CanvasRatio ratioTypeFromString(std::string ratioString);
    static std::string ratioStringFromType(cdom::CanvasRatio ratio);
    
    static CanvasRatio getCanvasRatio(std::shared_ptr<CutSame::CanvasConfig> &canvasConfig);
};

}

#endif /* CanvasConfigUtils_hpp */
