//
//  BDXBridgeMethod.m
//  BDXBridge
//
//  Created by Lizhen Hu on 2020/5/28.
//

#import "BDXBridgeMethod.h"
#import <Mantle/MTLModel.h>
#import <BDAssert/BDAssert.h>

@interface BDXBridgeMethod ()

@property (nonatomic, strong) BDXBridgeContext *context;

@end

@implementation BDXBridgeMethod

- (instancetype)initWithContext:(BDXBridgeContext *)context
{
    self = [super init];
    if (self) {
        _context = context;
    }
    return self;
}

- (BDXBridgeEngineType)engineTypes
{
    return BDXBridgeEngineTypeAll;
}

- (NSString *)methodName
{
    [self raiseExceptionWithSelector:_cmd];
    return nil;
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypeProtected;
}

- (BOOL)isDevelopmentMethod
{
    return NO;
}

- (BDXBridgeContext *)context
{
    if (!_context) {
        _context = [BDXBridgeContext new];
    }
    return _context;
}

- (Class)paramModelClass
{
    return nil;
}

- (Class)resultModelClass
{
    return nil;
}

- (void)callWithParamModel:(BDXBridgeModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    [self raiseExceptionWithSelector:_cmd];
}

- (void)raiseExceptionWithSelector:(SEL)selector
{
    BDAssert(NO, @"The method '%@' should be implemented by subclass '%@'.", NSStringFromSelector(selector), NSStringFromClass(self.class));
}

@end
