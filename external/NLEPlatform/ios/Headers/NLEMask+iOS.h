//
//  NLEMask+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/25.
//

#ifndef NLEMask_iOS_h
#define NLEMask_iOS_h

#import <Foundation/Foundation.h>
#import "NLETimeSpaceNode+iOS.h"
#import "NLESegmentMask+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEMask_OC : NLETimeSpaceNode_OC

/// 蒙版
@property (nonatomic, strong) NLESegmentMask_OC* segmentMask;
                                                         \
@end

NS_ASSUME_NONNULL_END

#endif /* NLEMask_iOS_h */
