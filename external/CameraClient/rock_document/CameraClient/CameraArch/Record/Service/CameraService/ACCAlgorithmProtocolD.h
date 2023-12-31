//
//  ACCAlgorithmProtocolD.h
//  CameraClient
//
//  Created by Fengfanhua.byte on 2021/11/10.
//

#import <CreationKitRTProtocol/ACCAlgorithmProtocol.h>

@protocol ACCAlgorithmProtocolD <ACCAlgorithmProtocol>

/**
 turn on  bach algorithm
 @param graphName define by business
 @param algorithmConfig config file is supported by effect
 @param algoType except type,  setAlgorithmResultsRequirement callback
 */
- (void)addBachAlgorithmName:(NSString *_Nullable)graphName config:(NSString *_Nullable)algorithmConfig algoType:(IESMMAlgorithmEffectBachType)algoType;


/*
 * remove all bach algorithm
 */
- (void)removeAllBachAlgorithm;


@end

