//
//  HMDEvilMethodTracer+private.h
//  AWECloudCommand
//
//  Created by maniackk on 2021/6/4.
//

#import "HMDEvilMethodTracer.h"
#import "HMDEMUploader.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDEvilMethodTracer (privateAPI)

@property (nonatomic, strong)HMDEMUploader *uploader;

- (char *)getEMParameter;

- (NSDictionary *)getEventsParameter:(integer_t)runloopCostTime runloopStartTime:(uint64_t)runloopStartTime runloopEndTime:(uint64_t)runloopEndTime;

- (NSDictionary *)getEventsParameter:(integer_t)cost
                           startTime:(uint64_t)startTime
                             endTime:(uint64_t)endTime
                               hitch:(NSTimeInterval)hitch
                         isScrolling:(BOOL)isScrolling;

- (void)registerKVO;
- (void)removeKVO;

@end

NS_ASSUME_NONNULL_END
