//
//  EMARouteMediator.h
//  EEMicroAppSDK
//
//  Created by houjihu on 2018/10/22.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OPAppUniqueID;

@interface EMARouteMediator : NSObject

/// 打开lark 聊天窗口
@property(nonatomic, copy, nullable) void (^enterChatBlock)(NSString * chatId, BOOL showBadge, OPAppUniqueID *_Nullable uniqueID, UIViewController *_Nullable controller);

/// 打开lark profile页
@property(nonatomic, copy, nullable) void (^enterProfileBlock)(NSString * _Nullable userId, OPAppUniqueID *_Nullable uniqueID, UIViewController *_Nullable controller);

//打开Bot页
@property(nonatomic, copy, nullable) void (^enterBotBlock)(NSString * botId, OPAppUniqueID *_Nullable uniqueID, UIViewController *_Nullable controller);

#pragma mark 支持头条圈小程序输入框@选择联系人

/// 获取选择联系人vc,是否多选
@property (nonatomic, copy, nullable) UIViewController * _Nullable (^getPickChatterVCBlock)(BOOL multi, BOOL ignore, BOOL externalContact, NSNumber * _Nullable enableExternalSearch, NSNumber * _Nullable showRelatedOrganizations, BOOL enableChooseDepartment, NSArray<NSString *> * _Nullable selectedUserIDs, BOOL hasMaxNum, NSInteger maxNum, NSString * _Nullable limitTips, NSArray<NSString *> * _Nullable disableIds, NSString * _Nullable exEmployeeFilterType);

/// 选择联系人之后小程序引擎需要执行的动作
@property (nonatomic, copy, nullable) dispatch_block_t _Nullable (^selectChatterNamesBlock)(NSArray<NSString *> * _Nullable chatterNames, NSArray<NSString *> * _Nullable chatterIDs, NSArray<NSString *> * _Nullable departmentIDs);

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
