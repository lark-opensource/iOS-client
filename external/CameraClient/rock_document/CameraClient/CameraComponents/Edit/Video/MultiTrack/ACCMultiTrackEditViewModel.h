//
//  ACCMultiTrackEditViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/9/15.
//

#import <Foundation/Foundation.h>
#import <CameraClient/ACCMultiTrackEditServiceProtocol.h>

@class AWEVideoPublishViewModel;
@protocol IESServiceProvider;

@interface ACCMultiTrackEditViewModel : NSObject <ACCMultiTrackEditServiceProtocol>

@property (nonatomic, strong, nullable) AWEVideoPublishViewModel *repository;
@property (nonatomic, weak, nullable) id<IESServiceProvider> serviceProvider;

+ (BOOL)enableMultiTrackWithPublishViewModel:(AWEVideoPublishViewModel * _Nullable)publishViewModel;

- (void)bindViewModel;
- (BOOL)enableMultiTrack;

@end
