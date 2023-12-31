//
//  DYOpenFollowModelViewController.h
//  Pods
//
//  Created by bytedance on 2022/8/1.
//

#import "DYOpenFollow.h"
NS_ASSUME_NONNULL_BEGIN

@interface DYOpenFollowViewModel: NSObject
@property (nonatomic, assign) DYOpenFollowViewType viewType;
@property (nonatomic, copy) NSString* openId;
@property (nonatomic, copy) NSString* targetOpenId;
@property (nonatomic, copy) NSString* accessToken;
@property (nonatomic, copy) NSString* nickname;
@property (nonatomic, copy) NSString* avatarURLString;
@property (nonatomic, assign) BOOL isFollowing;
@property (nonatomic, copy) DYOpenFollowCallback followCallback;
@property (nonatomic, copy) DYOpenCloseCallback closeCallback;
@property (nonatomic, copy) NSString *clientKey; // 如果不传会取初始化 OpenSDK 时的值
@end

@interface DYOpenFollowView : UIView
@property (nonatomic, copy) DYOpenFollowCallback followCallback;
@property (nonatomic, copy) DYOpenCloseCallback closeCallback;
@property (nonatomic, assign) DYOpenFollowViewType viewType;
@property (nonatomic, copy) NSString* openId;
@property (nonatomic, copy) NSString* targetOpenId;
@property (nonatomic, copy) NSString* accessToken;
@property (nonatomic, copy) NSString* nickname;
@property (nonatomic, copy) NSString* avatarURLString;
@property (nonatomic, copy) NSString* desc;
@property (nonatomic, assign) BOOL isFollowing;

- (instancetype)initWithViewModel:(DYOpenFollowViewModel *)model;

@end
NS_ASSUME_NONNULL_END
