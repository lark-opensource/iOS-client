//
//  KeyframeUtils.hpp
//  VideoTemplate
//
//  Created by zenglifeng on 2020/5/26.
//

#ifndef KeyframeUtils_hpp
#define KeyframeUtils_hpp

#include <stdio.h>
#include <vector>
#include <TemplateConsumer/Keyframe.h>
#include <TemplateConsumer/Keyframes.h>
#include <cdom/ModelType.h>

namespace cut {

    struct KeyframeUtils {
        public:
            static std::vector<std::shared_ptr<CutSame::Keyframe>> getAllKeyframes(std::shared_ptr<CutSame::Keyframes> keyframes);
        
            static cdom::KeyframeType getKeyframeType(const std::shared_ptr<CutSame::Keyframe> &keyframe);
            
            static cdom::KeyframeType getKeyframeTypeForString(const std::string &typeString);
            
            static std::string getKeyframeTypeString(cdom::KeyframeType type);
        
        private:
            template<typename T>
            static void __append(std::vector<std::shared_ptr<CutSame::Keyframe>> &list, const std::vector<T> &keyframes) {
                for (auto &keyframe: keyframes) {
                    if (keyframe != nullptr) {
                        list.push_back(keyframe);
                    }
                }
            };
    };

}

#endif /* KeyframeUtils_hpp */
