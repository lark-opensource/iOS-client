//
//  BDABTestExperimentUpdater.h
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDABTestManager.h"

@class BDABTestExperimentItemModel;

extern NSString * const kFetchABResultErrorDomain;

typedef void (^BDABTestCompletionBlock)(NSDictionary<NSString *, NSDictionary *> *jsonData, NSDictionary<NSString *, BDABTestExperimentItemModel *> *itemModels, NSError *error);

@interface BDABTestExperimentUpdater : NSObject

/**
 通过指定URL请求命中的实验数据
 
 @param completionBlock 请求完成的回调
 */
- (void)fetchABTestExperimentsWithURL:(NSString *)url completionBlock:(BDABTestCompletionBlock)completionBlock;

@end
