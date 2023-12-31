//
//  ACCRecordFlowServiceImpl.h
//  Pods
//
//  Created by liyingpeng on 2020/6/23.
//

#import <Foundation/Foundation.h>
#import "ACCRecordFlowService.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;
@protocol ACCCameraService;
@protocol ACCRecordConfigService;
@class AWEVideoPublishViewModel;

@interface ACCRecordFlowServiceImpl : NSObject <ACCRecordFlowService>

@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordConfigService> recordConfigService;
@property (nonatomic, weak) AWEVideoPublishViewModel *repository;

@end

NS_ASSUME_NONNULL_END
