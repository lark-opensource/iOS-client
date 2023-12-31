//
//  ACCMVTemplateVideoPlayViewController.h
//  CameraClient
//
//  Created by long.chen on 2020/3/9.
//

#import <UIKit/UIKit.h>

#import "ACCMVTemplateDetailViewController.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const ACCMVTemplateDidFinishVideoDataDownloadNotification;

FOUNDATION_EXTERN NSString *const ACCMVTemplateDidFinishVideoDataDownloadIDKey;

@interface ACCMVTemplateVideoPlayViewController : UIViewController <ACCMVTemplateVideoPlayProtocol>

@property (nonatomic, strong) id<ACCMVTemplateModelProtocol> templateModel;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, weak) id<ACCMVTemplateInteractionProtocol> interactionDelegate;

- (void)play;
- (void)pause;
- (void)stop;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
