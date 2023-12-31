//
//  BDPTracingExtension.h
//  Timor
//
//  Created by changrong on 2020/3/9.
//

#import <Foundation/Foundation.h>

/**
 * tracing extension的协议，需要包含以下内容:
 * 1. 支持序列化与反序列化
 * 2. 支持两个extension的merge操作
 */
@protocol BDPTracingExtension <NSObject>

- (void)mergeExtension:(id<BDPTracingExtension>)extension;

@end
