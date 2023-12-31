//
//  DouyinOpenSDKGeneralProfile.h
//  Pods
//
//  Created by bytedance on 2022/7/3.
//
#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import "DouyinOpenSDKProfile.h"

extern NSString * const DouyinCardSucceededNotification;

typedef void (^DouyinOpenSDKPresentProfileCompletion)(NSInteger errorCode, NSString* errorMsg);

typedef enum: NSUInteger {
    OpenProfileVCHostBig = 0,
    OpenProfileVCHostSmall = 1,
    OpenProfileVCClientBig = 2,
    OpenProfileVCClientSmall = 3
} DouyinOpenSDKProfileVCType;

@interface DouyinOpenSDKGeneralProfile : NSObject

+(void)presentDouyinProfileViewControllerWithContext:(DouyinOpenSDKProfileContext *)context backgroundImage:(UIImage *)image fromVC:(UIViewController *)fromVC completion:(DouyinOpenSDKPresentProfileCompletion)completion;
//仅测试接口
+(void)presentDouyinProfileViewControllerWithType:(DouyinOpenSDKProfileVCType)type context:(DouyinOpenSDKProfileContext *)context fromVC:(UIViewController *)fromVC completion:(DouyinOpenSDKPresentProfileCompletion)completion;
+(void)hideDouyinProfileViewController;

/// Profile 相关 storyboard
+ (UIStoryboard *)generalProfileStoryboard;

@end
