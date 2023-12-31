//
//  NLEFilter+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/25.
//

#ifndef NLEFilter_iOS_h
#define NLEFilter_iOS_h

#import <Foundation/Foundation.h>
#import "NLETimeSpaceNode+iOS.h"
#import "NLESegmentFilter+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEFilter_OC : NLETimeSpaceNode_OC
///滤镜片段
@property (nonatomic, strong) NLESegmentFilter_OC* segmentFilter;
                                                        \
@end

NS_ASSUME_NONNULL_END

#endif /* NLEFilter_iOS_h */
