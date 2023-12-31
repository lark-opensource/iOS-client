//
//  ACCMVTemplateDetailViewController.h
//  CameraClient
//
//  Created by long.chen on 2020/3/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMVTemplateVideoPlayProtocol <NSObject>

- (void)playWithAnimation;
- (void)pauseWithAnimation;

@end

@protocol ACCMVTemplateInteractionProtocol <NSObject>

- (void)playLoadingAnimation;
- (void)stopLoadingAnimation;

@end

@class AWEVideoPublishViewModel;
@protocol ACCMVTemplateModelProtocol;

@interface ACCMVTemplateDetailViewController : UIViewController

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) id<ACCMVTemplateModelProtocol> templateModel;
@property (nonatomic, copy) void (^didPickTemplateBlock)(id<ACCMVTemplateModelProtocol> templateModel);

- (void)play;
- (void)pause;
- (void)stop;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
