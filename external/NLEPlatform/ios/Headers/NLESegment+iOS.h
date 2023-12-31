//
//  NLESegment+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/7.
//

#import <Foundation/Foundation.h>
#import "NLENode+iOS.h"
#import "NLENativeDefine.h"
#import <CoreMedia/CoreMedia.h>
@class NLEResourceNode_OC;

NS_ASSUME_NONNULL_BEGIN

@interface NLESegment_OC : NLENode_OC
///获取片段时长，这里的时长会包括变速的
- (CMTime)getDuration;
/// 片段类型
- (NLEResourceType)getType;

/// 获取资源对象
/// 有一些Segment有Resource（比如：视频，特效）
/// 有一些Segment没有Resource（比如：文本贴纸，Emoji贴纸）
- (NLEResourceNode_OC*)getResNode;

@end

NS_ASSUME_NONNULL_END
