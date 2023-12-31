//
//  EMAPluginDiagnose.h
//  EEMicroAppSDK
//
//  Created by changrong on 2020/8/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMAPluginDiagnose : NSObject

/// 诊断执行的 Swift 接口，因处理逻辑比较复杂，新 API 下沉迁移过程中直接将 API 调用派发回此 plugin，内部逻辑随诊断能力开放再单独重构
/// @param commands 需要执行的诊断命令， API 调用参数
/// @param controller 小程序所处的 controller，从 API context 中取出
- (NSDictionary *)execDiagnoseCommandsSwiftWrapper:(NSArray<NSDictionary *> *)commands controller:(UIViewController * _Nullable)controller;
@end

NS_ASSUME_NONNULL_END
