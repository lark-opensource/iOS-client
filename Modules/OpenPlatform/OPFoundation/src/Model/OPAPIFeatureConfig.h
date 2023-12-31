//
//  OPAPIFeatureConfig.h
//  Timor
//
//  Created by lixiaorui on 2020/12/25.
//

// 本文件为API全形态适配上线灰度相关策略，目前配置在mina，由一个command enum来控制，后续可以扩充
// see: https://bytedance.feishu.cn/docs/doccnkBm38qgbJbnFh4TQOoBIH0#
// https://bytedance.feishu.cn/docs/doccny0pJDZRSRDmghNJExRcKlc
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, OPAPIFeatureCommand){
    OPAPIFeatureCommandUnknown,
    OPAPIFeatureCommandDoNotUse, // api返回不支持
    OPAPIFeatureCommandUseOld, // 使用旧的api
    OPAPIFeatureCommandRemoveOld, // 只走新api，不支持降级到旧api
    OPAPIFeatureCommandRestore // 走新api，并且支持降级到旧api
};

@interface OPAPIFeatureConfig : NSObject

@property (nonatomic, assign, readonly) OPAPIFeatureCommand apiCommand;

- (instancetype)initWithCommandString:(NSString *)command;

@end

NS_ASSUME_NONNULL_END

