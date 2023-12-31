//
//  Aspectutils.hpp
//  NLEPlatform
//
//  Created by bytedance on 2021/7/12.
//

#ifndef Aspectutils_h
#define Aspectutils_h

#include <cstdio>
#include <string>
#include <memory.h>
#include <NLESequenceNode.h>

namespace cut::utils {
        class NLE_EXPORT_CLASS AspectUtils {
        public:
            
            static std::pair<double, double> cropSizeForVideoSegment(std::shared_ptr<cut::model::NLESegmentVideo> videoSegment);

            static std::pair<double, double> maskAspectSize(std::pair<double, double> videoSize, std::pair<double, double> maskSize, double aspectRatio);
        };
    }

#endif /* Aspectutils_h */
