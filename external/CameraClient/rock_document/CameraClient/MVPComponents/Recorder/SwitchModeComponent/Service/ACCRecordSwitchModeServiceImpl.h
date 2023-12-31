//
//  ACCRecordSwitchModeServiceImpl.h
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/11/16.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCRecordModeFactory.h"
#import "ACCRecordConfigService.h"
#import <CreationKitArch/ACCVideoConfigProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCRecordSwitchModeServiceImpl : NSObject <ACCRecordSwitchModeService>

@property (nonatomic, strong) id<ACCRecordModeFactory> modeFactory;

@property (nonatomic, weak) AWEVideoPublishViewModel *repository;

@property (nonatomic, strong) id<ACCVideoConfigProtocol> videoConfig;

@property (nonatomic, strong) id<ACCRecordConfigService> configService;

@end

NS_ASSUME_NONNULL_END
