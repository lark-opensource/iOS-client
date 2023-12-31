//
//  ABTestExposureManager.h
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDABTestBaseExperiment.h"

/**
 BDABTestExposureManager
 
 维护已曝光实验的vid。
 加入新曝光实验的vid、剔除common接口不再下发的vid。
 */
@interface BDABTestExposureManager : NSObject

@property (nonatomic,assign) BOOL eventEnabled;

/**
 单例获取方法

 @return 单例
 */
+ (instancetype)sharedManager;


/**
 触发一个vid的曝光

 @param vid 这个vid将被加入曝光区
 */
- (void)exposeVid:(NSNumber *)vid;


/**
 获取曝光区内vid

 @return 曝光区内vid，以逗号分隔
 */
- (NSString *)exposureVidString;

@end
