//
//  ACCAPPSettingsProtocol.h
//  CameraClient
//
//  Created by lxp on 2019/11/18.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCAPPSettingsProtocol <NSObject>

// 是不是升级后首次打开
- (BOOL)isAppVersionUpdated;

- (void)removeVolumeViewWithVC:(UIViewController *)vc;

- (BOOL)needShowErrorDescription:(NSError *)error;

- (BOOL)enableBOE;

- (nullable NSString *)acc_deviceID;

- (BOOL)isLowPublishActiveness;

- (NSString *)stickerExploreScheme;
//自拍表情相关
//自拍表情生成超时时间，默认 10s
- (NSTimeInterval)xmojiGeneratePollTimeoutDuration;
//自拍表情假的进度条默认跑完的最快时间
- (NSTimeInterval)xmojiGenerateProgressLineMinTime;
//自拍表情协议许可跳转页面
- (NSString *)xmojiGeneratePrivacyHintURLString;

- (NSArray<NSString *> *)scanToLoginPathBlockList;

// 是否开启“允许访问相册位置”
@property (nonatomic, assign, readonly) BOOL disableExifPermission;

@end

FOUNDATION_STATIC_INLINE id<ACCAPPSettingsProtocol> ACCAPPSettings() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCAPPSettingsProtocol)];
}

NS_ASSUME_NONNULL_END
