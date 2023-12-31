//
//  BDXBridgeReportALogMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import <BDAlogProtocol/BDAlogProtocol.h>
#import "BDXBridgeReportALogMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"

@implementation BDXBridgeReportALogMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeReportALogMethod);

- (void)callWithParamModel:(BDXBridgeReportALogMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    BDXBridgeLogLevel level = paramModel.level;
    NSString *message = paramModel.message;
    NSString *tag = paramModel.tag;
    NSString *file = paramModel.codePosition.file;
    NSString *function = paramModel.codePosition.function;
    NSNumber *line = paramModel.codePosition.line;
    
    if (message.length > 0 && tag.length > 0 && level != BDXBridgeLogLevelUnknown) {
        bd_log_write(file.UTF8String, function.UTF8String, tag.UTF8String, [self mappedLogLevelWithLogLevel:level], line.intValue, message.UTF8String);
        bdx_invoke_block(completionHandler, nil, nil);
    } else {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The parameters message|tag should not be empty."]);
    }
}

- (kBDLogLevel)mappedLogLevelWithLogLevel:(BDXBridgeLogLevel)logLevel
{
    switch (logLevel) {
        case BDXBridgeLogLevelDebug: return kLogLevelDebug;
        case BDXBridgeLogLevelInfo: return kLogLevelInfo;
        case BDXBridgeLogLevelWarn: return kLogLevelWarn;
        case BDXBridgeLogLevelError: return kLogLevelError;
        default: return kLogLevelVerbose;
    }
}

@end
