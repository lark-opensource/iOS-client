//
//  BDPAppMetaUtils.h
//  Timor
//
//  Created by lixiaorui on 2020/9/8.
//

#import "OPAppVersionType.h"

// 此处为meta通用工具方法，适用各形态，无需与BDPModel依赖
// 待后续外部调用与BDPModel解耦后，可以直接用appmetaprotocol扩展实现
NS_ASSUME_NONNULL_BEGIN

@interface BDPAppMetaUtils : NSObject

/** versionType不为nil, 则是DebugMode */
+ (BOOL)metaIsDebugModeForVersionType:(OPAppVersionType)versionType;

/*
* 是否为候选版本，versionType为current或者audit
* 2019-5-9 用于对齐current和audit版本的运行逻辑，加载和调试逻辑不变 https://bytedance.feishu.cn/space/doc/doccnUtipTg9FWEgHOD1ow#tO89mB
*/
+ (BOOL)metaIsReleaseCandidateModeForVersionType:(OPAppVersionType)versionType;

@end

NS_ASSUME_NONNULL_END
