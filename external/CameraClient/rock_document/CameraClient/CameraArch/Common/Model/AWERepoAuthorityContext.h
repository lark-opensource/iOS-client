//
//  AWERepoAuthorityContext.h
//  CameraClient-Pods-AwemeCore
//
//  Created by ZhangJunwei on 2021/10/22.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AWEPublishPrivacyVerificationStatusType) {
    AWEPublishPrivacySecurityErrorTypeDefault = 0,
    AWEPublishPrivacySecurityErrorTypeValueIsNil = 1,
    AWEPublishPrivacySecurityErrorTypeValueIsIllegal = 2,
};

@interface AWERepoAuthorityContext : NSObject <NSCopying, NSCoding>

@property (nonatomic, assign) BOOL downloadIgnoreVisibility; //下载权限与可见范围解耦，服务端在消费侧透传，为true时，端上不必对非公开视频限制下载。
@property (nonatomic, assign) BOOL duetIgnoreVisibility; //合拍权限与可见范围解耦，服务端在消费侧透传，为true时，端上不必对非公开视频限制合拍。
@property (nonatomic, assign) BOOL storyShareIgnoreVisibility; //转发到日常权限与可见范围解耦，服务端在消费侧透传，为true时，端上不必对非公开视频限制分享到日常。

@property (nonatomic, assign) AWEPublishPrivacyVerificationStatusType downloadVerificationStatus; //下载权限校验状态。
@property (nonatomic, assign) AWEPublishPrivacyVerificationStatusType duetVerificationStatus; //合拍权限校验状态。
@property (nonatomic, assign) AWEPublishPrivacyVerificationStatusType storyShareVerificationStatus; //分享到日常权限校验状态。

@property (nonatomic, copy) NSString * _Nullable downloadTypeErrorMessage; //下载权限非法的错误信息
@property (nonatomic, copy) NSString * _Nullable itemDuetErrorMessage; //合拍权限非法的错误信息
@property (nonatomic, copy) NSString * _Nullable itemShareErrorMessage; //分享到日常权限非法的错误信息

- (BOOL)isDownloadTypeError;
- (BOOL)isItemDuetError;
- (BOOL)isItemShareError;

@end
