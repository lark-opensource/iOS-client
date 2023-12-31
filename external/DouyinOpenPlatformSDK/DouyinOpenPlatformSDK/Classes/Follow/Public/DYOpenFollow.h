//
//  DYOpenFollow.h
//  Pods
//
//  Created by bytedance on 2022/8/1.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    DouyinOpenFollowErrorCodeSuccess =  20000,
    DouyinOpenFollowErrorCodeUnknown = 20001,
    DouyinOpenFollowErrorCodeInvalidParam = 20002,
    DouyinOpenFollowErrorCodeCardTypeError = 20003,
    DouyinOpenFollowErrorCodeSecretAccount = 20005,
    DouyinOpenFollowErrorCodeNotSupportJumpContact = 20006,
    DouyinOpenFollowErrorCodeNotSupportJumpProfile = 20007,
    DouyinOpenFollowErrorCodeTargetUserNotAuthed = 20008,
} DYOpenFollowErrorCode;

typedef void (^DYOpenGetFollowViewCallback)(UIView * _Nullable followView, DYOpenFollowErrorCode errorCode, NSString* _Nullable errorMsg);
typedef void (^DYOpenCheckFollowingStatusCallback)(BOOL isFollowing, NSInteger errorCode, NSString* _Nullable errorMsg);
typedef void (^DYOpenFollowCallback)(NSInteger errorCode, NSString* _Nullable errorMsg);
typedef void (^DYOpenCloseCallback)(void);
typedef void (^DYOpenFollowUserCallback)(BOOL isFollowed, NSInteger errorCode, NSString* _Nullable errorMsg);

@interface DYOpenFollowCallbackModel : NSObject
@property (nonatomic, copy) DYOpenGetFollowViewCallback getFollowCallback;
@property (nonatomic, copy) DYOpenFollowCallback followCallback;
@property (nonatomic, copy) DYOpenCloseCallback closeCallback;
@end

typedef enum: NSUInteger {
    DYOpenFollowViewTypeWindow = 0,
    DYOpenFollowViewTypeBanner = 1,
} DYOpenFollowViewType;

@interface DYOpenCheckFollowingStatusModel: NSObject
@property (nonatomic, copy) DYOpenCheckFollowingStatusCallback followingStatusCallback;
@property (nonatomic, copy) NSString* openId;
@property (nonatomic, copy) NSString* targetOpenId;
@property (nonatomic, copy) NSString* accessToken;
@property (nonatomic, copy, nullable) NSString *clientKey; // 如果不传会取初始化 OpenSDK 时的值
@end

@interface DYOpenGetFollowViewModel: NSObject
@property (nonatomic, strong) DYOpenFollowCallbackModel* callbackModel;
@property (nonatomic, copy) NSString* openId;
@property (nonatomic, copy) NSString* targetOpenId;
@property (nonatomic, copy) NSString* accessToken;
@property (nonatomic, copy, nullable) NSString *clientKey; // 如果不传会取初始化 OpenSDK 时的值
@property (nonatomic, assign) DYOpenFollowViewType type;
@end

@interface DYOpenFollowUserModel: NSObject
@property (nonatomic, copy) DYOpenFollowUserCallback followUserCallback;
@property (nonatomic, copy) NSString* openId;
@property (nonatomic, copy) NSString* targetOpenId;
@property (nonatomic, copy) NSString* accessToken;
@end

@interface DYOpenFollow : NSObject

+(void)getDouyinFollowViewWithModel:(DYOpenGetFollowViewModel *)model;
+(void)checkFollowingStatusWithModel:(DYOpenCheckFollowingStatusModel *)model;
+(void)followUserWithModel:(DYOpenFollowUserModel *)model;

@end

NS_ASSUME_NONNULL_END
