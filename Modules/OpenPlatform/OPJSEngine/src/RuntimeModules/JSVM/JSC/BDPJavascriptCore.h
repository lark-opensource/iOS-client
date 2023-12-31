//
//  BDPJavascriptCore.h
//  Timor
//
//  Created by dingruoshan on 2019/6/20.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

#if DEBUG
#pragma mark - JSContextRenameForDebug
@interface JSContextRenameForDebug : JSContext
@end
#else
#define JSContextRenameForDebug JSContext
#endif


#if DEBUG
#pragma mark - JSVirtualMachineRenameForDebug
@interface JSVirtualMachineRenameForDebug : JSVirtualMachine
@end
#else
#define JSVirtualMachineRenameForDebug JSVirtualMachine
#endif

NS_ASSUME_NONNULL_END
