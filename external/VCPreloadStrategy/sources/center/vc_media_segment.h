//
//  vc_media_segment.hpp
//  VCPreloadStrategy
//
//  Created by bytedance on 2020/11/26.
//

#ifndef vc_media_segment_hpp
#define vc_media_segment_hpp

#include "vc_base.h"
#include "vc_info.h"
#include <stdio.h>

VC_NAMESPACE_BEGIN

class VCSegment : public VCInfo {
public:
    int mSegmentIndex;
    int mDuration;
    int mStartPosition;
    bool mIsLastSegment;
    bool mBitrateSwitchable;
    bool mIsDownloadStart;
    std::string mFileId;
};

VC_NAMESPACE_END

#endif /* vc_media_segment_hpp */
