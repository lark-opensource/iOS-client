//
//  ByteViewThreadBizScopedProxy.h
//  ByteView
//
//  Created by liujianlong on 2023/4/11.
//

#import <Foundation/Foundation.h>
#import "thread_biz_scope.h"

NS_ASSUME_NONNULL_BEGIN

@interface ByteViewThreadBizScopedProxy : NSProxy

@property(assign, nonatomic, readonly) ByteViewThreadBizScope scope;

- (instancetype)initWithScope:(ByteViewThreadBizScope)scope target:(id)target;

@end

NS_ASSUME_NONNULL_END
