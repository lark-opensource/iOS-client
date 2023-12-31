//
//	HMDMemoryGraphGenerator+Reportor.h
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/3/11. 
//

#import "HMDMemoryGraphGenerator.h"
#import "HMDMemoryGraphUploader.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDMemoryGraphGenerator (Reportor)

/// 云控触发内存分析
/// @param remainingMemory 最小预留内存，通过云控下发
/// @param completeBlock 完成回调，如果error是nil说明成功，且zipPath为压缩包.zip路径
- (void)cloudCommandGenerateWithRemainingMemory:(NSUInteger)remainingMemory
                                  completeBlock:(HMDMemoryGraphCloudControlCompleteBlock)completeBlock;

@end

NS_ASSUME_NONNULL_END
