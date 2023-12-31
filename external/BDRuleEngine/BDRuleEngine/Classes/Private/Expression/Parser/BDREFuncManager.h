//
//  BDREFuncManager.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>
#import "BDREExprRunner.h"
#import "BDREFunc.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREFuncManager : NSObject

+ (BDREFuncManager *)sharedManager;

- (void)registerFunc:(BDREFunc *)func;

- (BDREFunc *)getFuncFromSymbol:(NSString *)symbol;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
