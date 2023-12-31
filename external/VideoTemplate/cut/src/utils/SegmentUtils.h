//
//  SegmentUtils.hpp
//  LVTemplate
//
//  Created by ZhangYuanming on 2020/2/14.
//

#ifndef SegmentUtils_hpp
#define SegmentUtils_hpp

#include <stdio.h>
#include <TemplateConsumer/Segment.h>

namespace cut {

struct SegmentUtils {
    
    public:
    static const std::string SEGMENT_VIDEO_BLACK();
    static CutSame::Segment genSegmentVideoBlack(int64_t duration);
};

}

#endif /* SegmentUtils_hpp */
