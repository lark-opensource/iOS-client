//
//  DVECoreBeautyProtocol.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/14.
//

#import <Foundation/Foundation.h>
#import "DVECoreProtocol.h"
#import "DVEEffectValue.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVECoreBeautyProtocol <DVECoreProtocol>

/// 适用于选择美颜按钮，更新或者添加美颜，目前只支持全局美颜
/// @param value DVEEffectValue
/// @param commit 提交NLE（提交后可以undo）
- (void)addOrUpdateBeautyWithEffectValue:(DVEEffectValue *)value
                              needCommit:(BOOL)commit;

/// 移除所有美颜效果
- (void)deleteAllBeautyWithNeedCommit:(BOOL)commit;

/// 获取一个关于当前美颜效果的字典数组 "identifier" : 美颜资源唯一标识符  "intensity" : 美颜强度值
- (NSArray *)currentBeautyIntensity;

@end

NS_ASSUME_NONNULL_END
