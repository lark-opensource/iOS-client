//
//  CJPaySettingsManager.h
//  CJPay
//
//  Created by liyu on 2020/3/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define CJPayFetchSettingsSuccessNotification @"CJPayFetchSettingsSuccessNotification"

@class CJPaySettings;
@class CJPayIAPConfigModel;
@class CJPayContainerConfig;
@interface CJPaySettingsManager : NSObject

/*!
    业务方只需要调用settingInit这个方法就能完成settings的初始化，冷启动调用一次
 */
+ (void)settingsInit;

+ (instancetype)shared;


@property (nonatomic, strong, readonly, nullable) CJPaySettings *currentSettings;

@property (nonatomic, strong, readonly, nullable) CJPaySettings *remoteSettings;
@property (nonatomic, strong, readonly, nullable) CJPaySettings *localSettings;
@property (nonatomic, strong, readonly, nullable) CJPayIAPConfigModel *iapConfigModel;
@property (nonatomic, strong, readonly, nullable) CJPayContainerConfig *containerConfig;
@property (nonatomic, copy, readonly, nullable) NSDictionary *themeModelDic;
@property (nonatomic, copy, readonly, nullable) NSDictionary *settingsDict;

@end

@interface CJPaySettingsManager(QuickReadValue)

+ (BOOL)boolValueForKeyPath:(NSString *)keyPath;
+ (nullable NSString *)stringValueForKeyPath:(NSString *)keyPath;
+ (int)intValueForKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
