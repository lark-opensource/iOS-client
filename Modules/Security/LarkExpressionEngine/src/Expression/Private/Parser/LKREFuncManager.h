//
//  LKREFuncManager.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>
#import "LKREExprRunner.h"
#import "LKREFunc.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREFuncManager : NSObject

+ (LKREFuncManager *)sharedManager;

- (void)registerFunc:(LKREFunc *)func;

- (LKREFunc *)getFuncFromSymbol:(NSString *)symbol;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
