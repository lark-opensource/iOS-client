//
//  DVEMultipleTrackView+Clip.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/26.
//

#import "DVEMultipleTrackView.h"
#import "DVESegmentClipView.h"


typedef struct DVEAllowSegmentClipInfo {
    bool allowed;
    CGRect updateRect;
} DVEAllowSegmentClipInfo;

CG_INLINE DVEAllowSegmentClipInfo
DVEAllowSegmentClipInfoMake(bool allowed, CGRect updateRect)
{
    DVEAllowSegmentClipInfo info;
    info.allowed = allowed;
    info.updateRect = updateRect;
    return info;
}

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackView (Clip)<DVESegmentClipViewDelegate>

- (void)setupSegmentClipViewIfNeeded;

- (DVEAllowSegmentClipInfo)allowSegmentClipFromRect:(CGRect)originRect toRect:(CGRect)toRect;

- (void)updateSegmentClipViewFrameIfNeeded;

@end

NS_ASSUME_NONNULL_END
