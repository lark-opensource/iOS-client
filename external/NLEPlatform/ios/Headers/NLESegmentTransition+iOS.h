//
//  NLESegmentTransform+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/8.
//

#import <Foundation/Foundation.h>
#import "NLESegment+iOS.h"

NS_ASSUME_NONNULL_BEGIN

/// 转场
@interface NLESegmentTransition_OC : NLESegment_OC

/// 转场是否交叠，交叠的话此片段之后的片段的起始时间全部前移；不交叠的话，不影响时间轴
@property (nonatomic, assign) BOOL overlap;

/// 转场总时长
@property (nonatomic, assign) CMTime transitionDuration;

/// 转场素材资源
@property (nonatomic, strong) NLEResourceNode_OC* effectSDKTransition;
@property (nonatomic, assign) NLEMediaTransType mediaTransType;

- (NLEResourceType)getType;

- (NLEResourceNode_OC*)getResNode;

@end


NS_ASSUME_NONNULL_END
