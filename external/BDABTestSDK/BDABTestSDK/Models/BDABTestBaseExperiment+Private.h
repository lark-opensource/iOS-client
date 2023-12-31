//
//  BDABTestBaseExperiment+Private.h
//  AFgzipRequestSerializer
//
//  Created by xushuangqing on 2018/10/8.
//

#import "BDABTestBaseExperiment.h"
@class BDABTestExperimentItemModel;

@interface BDABTestBaseExperiment (Private)

/**
 获取实验取值
 支持多线程调用
 
 @param withExposure 是否触发曝光
 @return 实验取值model
 */
- (BDABTestExperimentItemModel *)getResultWithExposure:(BOOL)withExposure;

/**
 获取该实验是否已曝光

 @return 该实验是否已曝光
 */
- (BOOL)hasExposed;

@end
