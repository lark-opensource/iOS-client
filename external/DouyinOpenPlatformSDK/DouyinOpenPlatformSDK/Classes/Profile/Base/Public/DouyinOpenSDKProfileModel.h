//
//  DouyinOpenSDKProfileModel.h
//  DouyinOpenPlatformSDK
//
//  Created by bytedance on 2022/3/3.
//

#import "DouyinOpenSDKProfileVideoModel.h"
NS_ASSUME_NONNULL_BEGIN

// 展示类型，字符串枚举
typedef NSString * _Nullable DYOpenProfileShowType NS_TYPED_ENUM;
extern DYOpenProfileShowType const DYOpenProfileShowTypeLatest;
extern DYOpenProfileShowType const DYOpenProfileShowTypeCustom;
extern DYOpenProfileShowType const DYOpenProfileShowTypeHottest;
extern DYOpenProfileShowType const DYOpenProfileShowTypeCustomAndJump;

@interface DouyinOpenSDKProfileModel:NSObject
@property (nonatomic, copy) NSString* nickName;
@property (nonatomic, copy) NSString* location;
@property (nonatomic, copy) NSString* province;
@property (nonatomic, copy) NSString* city;
@property (nonatomic, copy) NSString* country;
@property (nonatomic, copy) NSString* clientName;
@property (nonatomic, copy) NSString* school;
@property (nonatomic, copy) NSString* birthdayString;
@property (nonatomic, copy) NSString* avatarURLString;
@property (nonatomic, assign) NSInteger gender; // 0:unknown 1:male 2:female
@property (nonatomic, assign) NSInteger fanCount;
@property (nonatomic, copy) NSArray<DouyinOpenSDKCallBackVideoModel*>* videoModels;
@property (nonatomic, assign) NSInteger videoDiggCount;
@property (nonatomic, assign) NSInteger followingCount;
@property (nonatomic, assign) NSInteger followerCount;
@property (nonatomic, assign) NSInteger isSecret;
@property (nonatomic, copy) DYOpenProfileShowType showType;
@property (nonatomic, assign) BOOL hasSetCustomVideo;
@property (nonatomic, assign) NSInteger customVideoCount;
@property (nonatomic, assign) NSInteger followingTarget;
@property (nonatomic, assign) BOOL authFollowStatus;
@property (nonatomic, assign) BOOL targetAuthFollowStatus;

@end

NS_ASSUME_NONNULL_END
