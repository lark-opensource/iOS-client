//
//  MaterialAnimationUtils.hpp
//  LVTemplate
//
//  Created by ZhangYuanming on 2020/2/14.
//

#ifndef MaterialAnimationUtils_hpp
#define MaterialAnimationUtils_hpp

#include <stdio.h>
#include <TemplateConsumer/Animations.h>

namespace cut {

struct MaterialAnimationUtils {
    const static std::string TYPE_LOOP;
    const static std::string TYPE_IN;
    const static std::string TYPE_OUT;
    
    static bool isLoop(const std::shared_ptr<CutSame::Animations> &animations);
    
    static std::string getInAnimPath(const std::shared_ptr<CutSame::Animations> &animations);

    static std::string getOutAnimPath(const std::shared_ptr<CutSame::Animations> &animations);

    static std::string getLoopAnimPath(const std::shared_ptr<CutSame::Animations> &animations);

    static uint64_t getInAnimDuration(const std::shared_ptr<CutSame::Animations> &animations);

    static uint64_t getOutAnimDuration(const std::shared_ptr<CutSame::Animations> &animations);

    static uint64_t getLoopAnimDuration(const std::shared_ptr<CutSame::Animations> &animations);
};

}

#endif /* MaterialAnimationUtils_hpp */
