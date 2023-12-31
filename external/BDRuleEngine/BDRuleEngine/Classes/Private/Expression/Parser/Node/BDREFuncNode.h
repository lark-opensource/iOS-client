//
//  BDREFuncNode.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREBaseNode.h"
#import "BDREFuncManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREFuncNode : BDREBaseNode

@property (nonatomic, strong, readonly) BDREFunc *func;
@property (nonatomic, copy, readonly) NSString *funcName;

- (nonnull instancetype)initWithFuncName:(nonnull NSString *)funcName func:(nullable BDREFunc *)func originValue:(nonnull NSString *)originValue index:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
