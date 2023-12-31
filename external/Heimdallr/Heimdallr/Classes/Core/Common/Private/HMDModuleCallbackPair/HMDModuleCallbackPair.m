//
//  HMDModuleCallbackPair.m
//  Heimdallr
//
//  Created by sunrunwang on 2019/4/17.
//

#import "HMDModuleCallbackPair.h"

@interface HMDModuleCallbackPair ()
@property(nonatomic, nonnull, readwrite) NSString *moduleName;
@property(nonatomic, nonnull, readwrite) HMDModuleCallback callback;
@end

@implementation HMDModuleCallbackPair

@synthesize moduleName = _moduleName, callback = _callback;

- (instancetype)initWithModuleName:(NSString *)moduleName callback:(HMDModuleCallback)callback {
    NSAssert(moduleName != nil && callback != nil, @"[FATAL ERROR] Please preserve current environment and contact Heimdallr developer ASAP.");
    if(moduleName == nil || callback == nil) return nil;
    if(self = [super init]) {
        _moduleName = moduleName;
        _callback = callback;
    }
    return self;
}

- (void)invokeCallbackWithModule:(id<HeimdallrModule> _Nullable)module isWorking:(BOOL)isWorking {
    self.callback(module, isWorking);
}

- (id)copyWithZone:(NSZone *)zone {
    __kindof HMDModuleCallbackPair *copied;
    if((copied = [HMDModuleCallbackPair allocWithZone:zone]) != nil) {
        copied->_moduleName = _moduleName;
        copied->_callback = _callback;
    }
    return copied;
}

- (BOOL)isEqual:(id)object {
    if(object != nil &&
       [object isKindOfClass:HMDModuleCallbackPair.class] &&
       [((__kindof HMDModuleCallbackPair *)object).moduleName isEqualToString:self.moduleName] &&
       ((__kindof HMDModuleCallbackPair *)object).callback == self.callback)
            return YES;
    return NO;
}

- (NSUInteger)hash {
    return _moduleName.length;
}

@end
