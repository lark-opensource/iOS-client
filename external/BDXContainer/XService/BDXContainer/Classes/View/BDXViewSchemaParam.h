//
//  BDXViewSchemaParam.h
//  Pods
//
//  Created by tianbaideng on 2021/4/14.
//
#import <BDXServiceCenter/BDXSchemaParam.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDXContext;

@interface BDXViewSchemaParam : BDXSchemaParam

/// 延迟展现loading的时间，以秒为单位
@property(nonatomic, strong) NSNumber *loadingDelayTime;

// 给view的tag，方便调试
@property(nonatomic, copy) NSString *viewTag;

@end

NS_ASSUME_NONNULL_END
