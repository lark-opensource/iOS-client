//
//  ACCRecordPropServiceImpl.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/12/14.
//

#import <Foundation/Foundation.h>
#import "ACCRecordPropService.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCameraService;
@protocol ACCRecordConfigService;
@protocol ACCRecordFrameSamplingServiceProtocol;
@class AWEVideoPublishViewModel;

@interface ACCRecordPropServiceImpl : NSObject <ACCRecordPropService>

@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordConfigService> recordConfigService;
@property (nonatomic, strong) id<ACCRecordFrameSamplingServiceProtocol> samplingService;
@property (nonatomic, weak) AWEVideoPublishViewModel *repository;
@property (nonatomic, copy, nullable) NSString *categoryKey;
@property (nonatomic, copy, nullable) NSString *categoryName;
@property (nonatomic, assign, getter=isFavorite) BOOL favorite;

@property (nonatomic, strong, nullable) IESEffectModel *prop;
@property (nonatomic, assign) ACCPropSource propSource;
@property (nonatomic, strong, nullable) NSIndexPath *propIndexPath;
@property (nonatomic, assign) BOOL isStickerHintViewShowing;
@property (nonatomic, assign) BOOL isAutoUseProp;

@end

NS_ASSUME_NONNULL_END
