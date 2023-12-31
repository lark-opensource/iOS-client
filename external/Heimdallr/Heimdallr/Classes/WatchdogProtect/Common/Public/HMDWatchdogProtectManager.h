//
//  HMDWatchdogProtectManager.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/8.
//

#import <Foundation/Foundation.h>


extern NSTimeInterval HMDWPDefaultTimeoutInterval; // 默认：1s，范围：[0.1 - 5.0]
extern NSTimeInterval HMDWPDefaultLaunchThreshold; // 默认：5s
extern BOOL HMDWPDefaultUIPasteboardProtect;
extern BOOL HMDWPDefaultUIApplicationProtect;
extern BOOL HMDWPDefaultYYCacheProtect;
extern BOOL HMDWPDefaultNSUserDefaultProtect;

extern bool HMDWPDispatchWorkItemEnabled; // 尝试修复卡死的开关

@protocol HMDWatchdogProtectDetectProtocol;

@interface HMDWatchdogProtectManager : NSObject

+ (instancetype _Nullable )sharedInstance;

// 卡死保护等待的最长时间 默认：1s， 范围：[0.1 - 5.0] (同步等待的时间, 超过这个时间, 那么返回 nil)
//                                              (等待还在继续, 不过是异步的而已, 然后最高等待时间是写死的 HMDWPExceptionMaxWaitTime)
@property(nonatomic, assign)NSTimeInterval timeoutInterval;

// 启动开始判定阈值，默认：5s (这个参数保留字段，还没有用到)
@property(nonatomic, assign)NSTimeInterval launchThreshold;

// UIPasteboard剪切板保护
@property(nonatomic, assign)BOOL UIPasteboardProtect;

// UIApplication保护
@property(nonatomic, assign)BOOL UIApplicationProtect;

// YYCache保护
@property(nonatomic, assign)BOOL YYCacheProtect;

// NSUserDefault保护
@property(nonatomic, assign)BOOL NSUserDefaultProtect;

// 卡死保护动态下发
- (void)setDynamicProtectOnMainThread:(NSArray<NSString *> * _Nullable)mainThreadProtectCollection
                          onAnyThread:(NSArray<NSString *> * _Nullable)anyThreadProtectCollection;

@property(nonatomic, readonly, nullable) NSString *currentProtectedMethodDescription;

// 手动设置YYCache卡死保护的开启/关闭
// 注意：该方法须在Heimdallr启动前调用
- (void)turnOnYYCacheProtectIgnoreCloudSetting:(BOOL)turnOn;
- (void)turnOnYYCacheProtectIgnorCloudSetting:(BOOL)turnOn __attribute__((deprecated("Please use turnOnYYCacheProtectIgnoreCloudSetting:")));

@end

