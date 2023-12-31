//
//  ACCRecorderLivePhotoProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by lingbinxing on 2021/8/5.
//

#import <Foundation/Foundation.h>
#import "ACCRepoLivePhotoModel.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@protocol ACCLivePhotoConfigProtocol, ACCLivePhotoResultProtocol;

/// LivePhoto record capability
@protocol ACCRecorderLivePhotoProtocol <NSObject>

/// is recording LivePhoto
- (BOOL)isLivePhotoRecording;

/// start record LivePhoto
/// @param configBlock config setup
/// @param progress current duration callback
/// @param completion finish callback
- (void)startRecordLivePhotoWithConfigBlock:(void(^)(id<ACCLivePhotoConfigProtocol> config))configBlock
                                   progress:(void(^ _Nullable)(NSTimeInterval currentDuration))progress
                                 completion:(void(^ _Nullable)(id<ACCLivePhotoResultProtocol> _Nullable data, NSError * _Nullable error))completion;

@end

/// LivePhoto record config
@protocol ACCLivePhotoConfigProtocol <NSObject, NSCopying>

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;
@property (nonatomic, assign) NSTimeInterval recordInterval;
@property (nonatomic, assign) NSTimeInterval recordDuration;
@property (nonatomic, copy, nullable) void(^stepBlock)(id<ACCLivePhotoConfigProtocol> config, NSInteger current, NSInteger total, NSInteger expectedTotal);
@property (nonatomic, copy, nullable) void(^willCompleteBlock)(id<ACCLivePhotoConfigProtocol> config);

@end

/// LivePhoto record result
@protocol ACCLivePhotoResultProtocol <NSObject>

@property (nonatomic, strong, readonly) id<ACCLivePhotoConfigProtocol> config;
@property (nonatomic, copy  , readonly) NSArray<NSString *> *framePaths;
@property (nonatomic, assign, readonly) CGFloat contentRatio;

@end

NS_ASSUME_NONNULL_END
