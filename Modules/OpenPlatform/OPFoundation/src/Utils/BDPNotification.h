//
//  BDPNotification.h
//  Timor
//
//  Created by 王浩宇 on 2018/11/15.
//

#ifndef BDPNotification_h
#define BDPNotification_h

// 小程序 - UniqueID -> AppId+VersionType
#define kBDPUniqueIDUserInfoKey                     @"kBDPUniqueIDUserInfoKey"

// 小程序 - 前后台通知
///触发自BDPAppController的viewWillAppear
#define kBDPEnterForegroundNotification             @"kBDPEnterForegroundNotification"
//触发自 BDPBaseContainerController,BDPAppController viewDidDisappear
#define kBDPEnterBackgroundNotification             @"kBDPEnterBackgroundNotification"
//触发自 BDPAppController viewDidAppear，目前(v4.11)仅用于slardar统计添加app_id的场景
#define kBDPDidEnterForegroundNotification          @"kBDPDidEnterForegroundNotification"

// 小程序 - 进入/退出通知
// 参数：'type' -> 'BDPTypeNativeApp'
#define kBDPEnterNotification                       @"kBDPEnterNotification"
#define kBDPExitNotification                        @"kBDPExitNotification"
#define kBDPExitNotificationIsRebootKey             @"is_reboot"
#define kBDPExitBotificationLaunchFromKey           @"launch_from"

// 小程序 - 系统中断通知
// 参数：'kBDPInterruptionStatusUserInfoKey' -> YES(中断), NO(恢复)
#define kBDPInterruptionNotification                @"kBDPInterruptionNotification"
#define kBDPInterruptionStatusUserInfoKey           @"kBDPInterruptionStatusUserInfoKey"

// 小程序 V1 - 刚进入后台时的 API 调用中断通知
// 小程序 V2 - 进入后台一段时间后的 API 调用中断通知
#define kBDPAPIInterruptionV1Notification           @"kBDPAPIInterruptionV1Notification"
#define kBDPAPIInterruptionV2Notification           @"kBDPAPIInterruptionV2Notification"
#define kBDPInterruptionUserInfoStatusKey           @"kBDPInterruptionUserInfoStatusKey"

// 小程序 - OnDocumentReady
#define kBDPAppDocumentReadyNotification            @"kBDPAppDocumentReadyNotification"
#define kBDPAppPageIDUserInfoKey                    @"kBDPAppPageIDUserInfoKey"


// 小程序 - 切换页面通知
#define kBDPSwitchPageNotification                  @"kBDPSwitchPageNotification"
#define kBDPPageVCKey                               @"kBDPPageVCKey"
#define kBDPIsPageLeavingKey                        @"kBDPIsPageLeavingKey"

// 小程序 - 音频中断通知
#define kBDPAudioInterruptionNotification           @"kBDPAudioInterruptionNotification"
#define kBDPAudioInterruptionOperationUserInfoKey   @"kBDPAudioInterruptionOperationUserInfoKey"

// 小程序 - 崩溃通知
#define kBDPAppPageTerminatedNotification           @"kBDPAppPageTerminatedNotification"
#define kBDPAppPageTerminatedUserInfoTypeKey        @"kBDPAppPageTerminatedUserInfoTypeKey"
#define kBDPAppPageFactoryReloadNotification        @"kBDPAppPageFactoryReloadNotification"

// 小程序 - 资源加载失败通知
#define kBDPDataLoadErrorNotification               @"kBDPDataLoadErrorNotification"
#define kBDPDataLoadErrorObjectUserInfoKey          @"kBDPDataLoadErrorObjectUserInfoKey"
#define kBDPDataLoadErrorObjectVisibleKey           @"kBDPDataLoadErrorObjectVisibleKey"
// 小程序 common 的reader 加载完之后的回调。
#define kBDPCommonReaderReadyNotification           @"kBDPCommonReaderReadyNotification"
#define kBDPSnapshotRenderReadyNotification         @"kBDPSnapshotRenderReadyNotification"

// 小程序 common 的 moreBtnBadge 更新的回调。
#define kBDPCommonMoreBtnBadgeUpdateNotification    @"kBDPCommonMoreBtnBadgeUpdateNotification"
#define kBDPCommonMoreBtnBadgeUpdateUniqueIDKey     @"kBDPCommonMoreBtnBadgeUpdateUniqueIDKey"
#define kBDPCommonMoreBtnBadgeUpdateNumKey        @"kBDPCommonMoreBtnBadgeUpdateNumKey"

#endif /* BDPNotification_h */
