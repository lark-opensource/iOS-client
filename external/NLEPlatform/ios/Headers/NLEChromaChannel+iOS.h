//
//  NLEChromaChannel+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/25.
//

#ifndef NLEChromaChannel_iOS_h
#define NLEChromaChannel_iOS_h
#import <Foundation/Foundation.h>
#import "NLETimeSpaceNode+iOS.h"
#import "NLESegmentChromaChannel+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEChromaChannel_OC : NLETimeSpaceNode_OC
@property (nonatomic, strong) NLESegmentChromaChannel_OC* segmentChromaChannel;
                                                        \
@end

NS_ASSUME_NONNULL_END

#endif /* NLEChromaChannel_iOS_h */
