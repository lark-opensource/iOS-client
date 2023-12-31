//
//  ACCMVTemplateInteractionViewController.h
//  CameraClient
//
//  Created by long.chen on 2020/3/9.
//

#import <UIKit/UIKit.h>

#import "ACCMVTemplateDetailViewController.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const ACCMVTemplateDidFavoriteNotification;
FOUNDATION_EXTERN NSString *const ACCMVTemplateDidUnFavoriteNotification;

FOUNDATION_EXTERN NSString *const ACCMVTemplateFavoriteTemplateKey;

@interface ACCMVTemplateInteractionViewController : UIViewController <ACCMVTemplateInteractionProtocol>

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) id<ACCMVTemplateModelProtocol> templateModel;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, weak) id<ACCMVTemplateVideoPlayProtocol> videoPlayDelegate;
@property (nonatomic, copy) void (^didPickTemplateBlock)(id<ACCMVTemplateModelProtocol> templateModel);

@end

NS_ASSUME_NONNULL_END
