//
//  BDPJavascriptCore.m
//  Timor
//
//  Created by dingruoshan on 2019/6/20.
//

#import "BDPJavascriptCore.h"
//#import "BDPUtils.h"
#import "OPJSEngineMacroUtils.h"

#if DEBUG
#pragma mark - JSContextRenameForDebug
@implementation JSContextRenameForDebug
- (instancetype)init
{
    self = [super init];
    if (self) {
        OPDebugNSLog(@"[JSAsync Debug] JSContext init %@",@([self hash]));
    }
    return self;
}
- (instancetype)initWithVirtualMachine:(JSVirtualMachine *)virtualMachine
{
    self = [super initWithVirtualMachine:virtualMachine];
    if (self) {
        OPDebugNSLog(@"[JSAsync Debug] JSContext init %@",@([self hash]));
    }
    return self;
}
- (void)dealloc
{
    OPDebugNSLog(@"[JSAsync Debug] JSContext dealloc %@",@([self hash]));
}
@end
#else
#define JSContextRenameForDebug JSContext
#endif


#if DEBUG
#pragma mark - JSVirtualMachineRenameForDebug
@implementation JSVirtualMachineRenameForDebug
- (instancetype)init
{
    self = [super init];
    if (self) {
        OPDebugNSLog(@"[JSAsync Debug] JSVirtualMachine init %@",@([self hash]));
    }
    return self;
}
- (void)dealloc
{
    OPDebugNSLog(@"[JSAsync Debug] JSVirtualMachine dealloc %@",@([self hash]));
}
@end
#else
#define JSVirtualMachineRenameForDebug JSVirtualMachine
#endif
