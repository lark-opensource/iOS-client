//
//  AWEPrivacyPermissionTypeDefines.h
//  CameraClient-Pods-AwemeCore
//
//  Created by ZhangJunwei on 2021/10/25.
//

#import <Foundation/Foundation.h>

//用户设置的合拍权限,对应消费侧下发AWEDuetAuthType = AWEAuthorDuetPermissionType + 服务端业务限制
typedef NS_ENUM(NSInteger, AWEAuthorDuetPermissionType) {
    AWEAuthorDuetPermissionTypeAll = 0, // 所有人
    AWEAuthorDuetPermissionTypeOnlySelf = 1, // 仅自己
    //AWEAuthorDuetPermissionTypeAds = 2, // 广告视频不可合拍，服务端判断，非用户可设置，为了方便服务端做字段映射，新增权限类型不使用该值。
    AWEAuthorDuetPermissionTypeFriends = 3, // 仅互关朋友
};


//用户设置的分享到日常权限,消费侧复用了AWEDuetAuthType作为item_share的枚举类型。
typedef NS_ENUM(NSInteger, AWEAuthorStorySharePermissionType) {
    AWEAuthorStorySharePermissionTypeAll = 0, // 所有人
    AWEAuthorStorySharePermissionTypeOnlySelf = 1, // 仅自己
    //AWEAuthorStorySharePermissionTypeAds = 2, // 广告视频不可合拍，服务端判断，非用户可设置，为了方便服务端做字段映射，新增权限类型不使用该值。
    AWEAuthorStorySharePermissionTypeFriends = 3, // 仅互关朋友
};


//用户设置的下载权限，对应消费侧下发AWEVideoControlPreventDownloadType = AWEAuthorDownloadPermissionType + 服务端业务限制
typedef NS_ENUM(NSInteger, AWEAuthorDownloadPermissionType) {
    AWEAuthorDownloadPermissionTypeAll = 0, // 所有人可下载
    //1，2，4 - 8为服务端判断下发，为了方便服务端做字段映射，新增权限类型不使用以上值。
    AWEAuthorDownloadPermissionTypeOnlySelf = 3, // 仅自己可下载
};

/*
 服务端prevent_download_type下发逻辑：
 prevent_download_type 状态
 0 可以下载
 1 水印未准备好
 2 审核未通过或未经过人工审核
 3 不允许他人下载
 4 版权问题不允许下载
 5 hide button
 6 xigua author banned
 7 日常不支持下载
 8 images prohibited
 */
