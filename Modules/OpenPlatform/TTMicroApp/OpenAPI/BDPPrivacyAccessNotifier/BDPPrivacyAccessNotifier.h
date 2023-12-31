//
//  BDPPrivacyAccessNotifier.h
//  AFgzipRequestSerializer
//
//  Created by zhangquan on 2019/9/25.
//

#import <Foundation/Foundation.h>

// 隐私权限访问状态
typedef NS_OPTIONS(NSInteger, BDPPrivacyAccessStatus) {
    BDPPrivacyAccessStatusNone = 0,
    BDPPrivacyAccessStatusMicrophone  = 1 << 0,   // 隐私权限访问状态 - 麦克风
    BDPPrivacyAccessStatusLocation    = 1 << 1,   // 隐私权限访问状态 - 地理位置
};

// 更多菜单权限类型(等待重构)
typedef NS_ENUM(NSInteger, BDPMorePanelPrivacyType) {
    BDPMorePanelPrivacyTypeNone = 0,
    BDPMorePanelPrivacyTypeMicrophone,
    BDPMorePanelPrivacyTypeLocation
};

@class BDPPrivacyAccessNotifier;
@protocol BDPPrivacyAccessNotifyDelegate <NSObject>

/// @brief 隐私访问状态回调，在主线程上回调
- (void)privacyAccessNotifier:(BDPPrivacyAccessNotifier *)notifier didChangePrivacyAccessStatus:(BDPPrivacyAccessStatus)status;

@end

/**
 小程序隐私访问通知管理
 */
@interface BDPPrivacyAccessNotifier : NSObject

+ (instancetype)sharedNotifier;

/**
 @brief当前隐私权限访问状态
 */
@property (atomic, readonly) BDPPrivacyAccessStatus currentStatus;

/**
 @brief 添加「隐私访问状态改变时」需要通知到的代理对象
 @param delegate 代理对象
 @note 这里delegate采用的是weak reference，因此不手动移除也没关系
 */
- (void)addDelegate:(id<BDPPrivacyAccessNotifyDelegate>)delegate;

/**
 @brief 移除「隐私访问状态改变时」需要通知到的代理对象
 @param delegate 代理对象
 */
- (void)removeDelegate:(id<BDPPrivacyAccessNotifyDelegate>)delegate;

/**
 @brief 设置「指定隐私权限类型」的使用状态
 @param status 指定隐私权限类型
 @param isUsing 是否正在使用
 */
- (void)setPrivacyAccessStatus:(BDPPrivacyAccessStatus)status isUsing:(BOOL)isUsing;

@end
