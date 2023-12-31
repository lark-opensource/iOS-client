//
//  ACCAlgorithmProtocol.h
//  Pods
//
//  Created by liyingpeng on 2020/6/4.
//

#ifndef ACCAlgorithmProtocol_h
#define ACCAlgorithmProtocol_h

#import "ACCCameraWrapper.h"
#import "ACCCameraSubscription.h"
#import "ACCAlgorithmEvent.h"

#import <TTVideoEditor/IESMMParamModule.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCAlgorithmProtocol <ACCCameraWrapper, ACCCameraSubscription>

@property (nonatomic, assign) BOOL lastRedPacketRecognised;
@property (nonatomic, assign) BOOL hasDetectMale;
@property (nonatomic, assign, readonly) IESMMAlgorithm externalAlgorithm;

- (void)enableEffectExternalAlgorithm:(BOOL)enable;

/**
 Next frame enforces detection algorithm
 */
- (void)forceDetectBuffer:(NSInteger)count;

/*
 Append the new detection algorithm callback
 */
- (void)appendAlgorithm:(IESMMAlgorithm)algorithm;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCAlgorithmProtocol_h */
