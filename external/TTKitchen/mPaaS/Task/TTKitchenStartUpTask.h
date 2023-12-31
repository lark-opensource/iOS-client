//
//  BDSettingsStartUpTask.h
//  BDStartUp
//
//  Created by bob on 2020/1/16.
//

#import <BDStartUp/BDStartUpTask.h>

NS_ASSUME_NONNULL_BEGIN

/// Config自定义配置参考如下，需要在BDAppCustomConfigFunction中
/// 仅做简单配置，请勿进行耗时操作
/// https://bytedance.feishu.cn/docs/LpllCSTfSs0sj5CsvVzcQb
///
/**
#import <BDStartUp/BDStartUpGaia.h>
#import <BDStartUp/BDSettingsStartUpTask.h>
 
BDAppCustomConfigFunction() {
    [TTKitchenStartUpTask sharedInstance].enabled = xxx;
 }
 */

FOUNDATION_EXTERN NSString * const BDStartUpSettingsDidReturnNotification;

@interface TTKitchenStartUpTask : BDStartUpTask

@property (nonatomic, copy) NSString *settingsHost; /// CN default https://is.snssdk.com

+ (instancetype)sharedInstance;

- (void)synchronizeSettings;

@end

NS_ASSUME_NONNULL_END
