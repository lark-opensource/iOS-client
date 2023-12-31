//
//  AWECameraManager.h
//  Aweme
//
//  Created by Liu Bing on 9/6/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

/// You should never use this class outside Studio module. Try to find out interface encapsuled in AWEStudioModuleService
@interface AWECameraManager : NSObject

@property (nonatomic, strong) NSMutableSet *taskIdSet;
@property (nonatomic, assign) BOOL shouldPreventNewRecordController;

+ (instancetype)sharedManager;

// 弱引用一个recorder
- (void)addRecorder:(UIViewController *)recorder;
// 当前所有弱引用的recorders
- (NSArray<UIViewController *> *)allRecorders;

@end
