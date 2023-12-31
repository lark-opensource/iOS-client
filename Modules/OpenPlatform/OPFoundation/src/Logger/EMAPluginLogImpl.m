//
//  EMAPluginLogImpl.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/2/25.
//

#import "EMAPluginLogImpl.h"
#import <OPFoundation/EMADebugUtil.h>
#import <OPFoundation/BDPTracingManager.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/OPFoundation-Swift.h>

@implementation EMAPluginLogImpl

+ (void)bdp_LogWithLevel:(BDPLogLevel)level tag:(NSString * _Nullable)tag tracing:(NSString * _Nullable)tracing fileName:(NSString * _Nullable)fileName funcName:(NSString * _Nullable)funcName line:(int)line  content:(NSString * _Nullable)content {
    //  补充前缀，便于筛选
    if (BDPIsEmptyString(tag)) {
        tag = @"gadget";
    } else {
        tag = [@"gadget|" stringByAppendingString:tag];
    }
    // 日志过滤
    if ([self filteredLogWithTag:tag]) {
        return;
    }
    // tracing 兼容，如果没有传入tracing，使用当前进程的tracing
    // 由于container tracing注册较晚，为了安全性，会多判一次空
    if (BDPIsEmptyString(tracing)) {
        tracing = [BDPTracingManager getThreadTracing].traceId ?: BDPTracingManager.sharedInstance.containerTrace.traceId;
        tracing = tracing ?: @"";
    }

    // 内容安全过滤
    // 日志由 EMAProtocolImpl 指定到 OPLogProxy 处理，敏感内容由 OPLogAuditor 过滤

#ifndef DEBUG
        if (level != BDPLogLevelDebug || [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDEnableDebugLog].boolValue) {
#else
        if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDEnableDebugLog].boolValue) {
#endif
            [BDPLoggerHelper logWithLevel:level tag:tag filename:fileName.lastPathComponent func_name:funcName line:line content:content logId:tracing];
        }
}

+ (BOOL)filteredLogWithTag:(NSString *)tag {
    if ([tag isEqualToString:@"BDP(monitor)"]) {
        return YES;
    }
    return NO;
}

@end
