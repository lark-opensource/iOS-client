//
//  BDPAppLoadManager+Launch.h
//  Timor
//
//  Created by lixiaorui on 2020/7/26.
//

// 根据该文档：https://bytedance.larksuite.com/docs/doccnBIjffEN1fK0VK5h8djexg8#，
// 预处理相关逻辑保留为原始逻辑

#import "BDPAppLoadManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPAppLoadManager (Launch)

/// 应用冷启动时预处理
- (void)preparationForColdLaunch;

@end

NS_ASSUME_NONNULL_END
