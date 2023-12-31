//
//  DouyinOpenSDKProfile.h
//  DouyinOpenPlatformSDK
//
//  Created by bytedance on 2022/3/3.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import "DouyinOpenSDKProfileModel.h"
#import "DouyinOpenSDKProfileVideoModel.h"
#import "DouyinOpenSDKProfileContext.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    DouyinOpenProfileErrorCodeSuccess =  20000,
    DouyinOpenProfileErrorCodeUnknown = 20001,
    DouyinOpenProfileErrorCodeInvalidParam = 20002,
    DouyinOpenProfileErrorCodeCardTypeError = 20003,
    DouyinOpenProfileErrorCodeSecretAccount = 20005,
    DouyinOpenProfileErrorCodeNotSupportJumpContact = 20006,
    DouyinOpenProfileErrorCodeNotSupportJumpProfile = 20007,
    DouyinOpenProfileErrorCodeTargetUserNotAuthed = 20008,
    DouyinOpenProfileErrorCodeInvalidVideo = 21001,
    DouyinOpenProfileErrorCodeInvalidVideoIndex = 21002,
    DouyinOpenProfileErrorCodeInvalidWindowType = 21003,
    DouyinOpenProfileErrorCodeShowing = 21004, // 页面展示中
} DouyinOpenSDKProfileErrorCode;

typedef enum : NSUInteger {
    DouyinOpenSDKProfileCardMLBB,
    DouyinOpenSDKProfileCardGeneral,
} DouyinOpenSDKProfileCardType;

@class AVPlayer;
extern NSString * const DouyinCardSucceededNotification;

typedef void (^DouyinOpenSDKPlayJumpCompletion)(NSInteger errorCode, NSString* errorMsg);
typedef void (^DouyinOpenSDKProfileCompletion)(NSInteger errorCode, NSString* errorMsg);
typedef void (^DouyinOpenSDKProfileModelCompletion)(NSInteger errorCode, NSString * _Nullable errorMsg, DouyinOpenSDKProfileModel * _Nullable profileModel);

typedef enum : NSUInteger {
    VideoStatePlaying,
    VideoStatePaused,
    VideoStateFinished,
} VideoState;

typedef enum : NSUInteger {
    VideoActionReplay,
    VideoActionJumpToFullScreen,
    VideoActionJumpToMiniPlay,
    VideoActionClose,
} VideoActionType;


typedef void (^DouyinOpenSDKVideoStateCallback)(VideoState state);
typedef void (^DouyinOpenSDKVideoPrePlayCallback)(NSInteger newIndex);
typedef void (^DouyinOpenSDKVideoNextPlayCallback)(NSInteger newIndex);
typedef void (^DouyinOpenSDKVideoDidFinishPlayingCallback)(NSInteger index);
typedef void (^DouyinOpenSDKVideoMiniPlayCallback)(AVPlayer *player, NSInteger currentIndex, CMTime currentTime, BOOL isFinished, UIImage *lastFrameImg);
typedef void (^DouyinOpenSDLVideoActionCallBack)(VideoActionType actionType);
typedef void (^DouyinOpenSDKVideoErrorCallback)(DouyinOpenSDKProfileErrorCode errorCode);

@interface DouyinOpenSDKVideoCallbackModel : NSObject

@property (nonatomic, copy) DouyinOpenSDKVideoStateCallback videoStateCallback;
@property (nonatomic, copy) DouyinOpenSDKVideoPrePlayCallback prePlayCallback;
@property (nonatomic, copy) DouyinOpenSDKVideoNextPlayCallback nextPlayCallback;
@property (nonatomic, copy) DouyinOpenSDKVideoDidFinishPlayingCallback didFinishPlayingCallback;
@property (nonatomic, copy) DouyinOpenSDLVideoActionCallBack videoActionCallBack;
@property (nonatomic, copy) DouyinOpenSDKVideoErrorCallback videoErrorCallback;

@end

@interface DouyinOpenSDKProfile : NSObject

+ (void)jumpToContactWithOpenId:(NSString *)openId targetOpenId:(NSString *)targetOpenId completion:(nullable DouyinOpenSDKPlayJumpCompletion)completion;
+ (void)jumpToProfileWithOpenId:(NSString *)openId targetOpenId:(NSString *)targetOpenId extraParams:(nullable NSDictionary <NSObject *, id> *)extraParams completion:(nullable DouyinOpenSDKPlayJumpCompletion)completion;
+(BOOL)canJump;

+(NSString *)cardTypeStringFromCardType:(DouyinOpenSDKProfileCardType)cardType;
+(void)updateProfileShowType:(DYOpenProfileShowType)showType cardType:(DouyinOpenSDKProfileCardType)cardType openId:(NSString *)openId accessToken:(NSString *)accessToken completion:(DouyinOpenSDKProfileCompletion)completion;

@end

NS_ASSUME_NONNULL_END
