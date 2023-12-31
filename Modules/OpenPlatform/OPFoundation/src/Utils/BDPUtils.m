//
//  BDPUtils.m
//  Timor
//
//  Created by MacPu on 2019/1/2.
//

#import "BDPUtils.h"
#import "BDPBundle.h"
#import "BDPNetworking.h"
#import "BDPTracingManager.h"

#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>

#import <ECOInfra/OPError.h>
#import <ECOProbe/OPMonitorCode.h>
#import <LarkStorage/LarkStorage-swift.h>

void BDPExecuteTracing(dispatch_block_t block)
{
    if (!block) { return; }
    BDPTracing *tracing = [BDPTracingManager getThreadTracing];
    [BDPTracingManager doBlock:^{
        block();
    } withLinkTracing:tracing];
}

void BDPExecuteOnMainQueue(dispatch_block_t block)
{
    if (!block) { return; }
    dispatch_block_t tracingBlock = [BDPTracingManager convertTracingBlock:block];
    if (BDPIsMainQueue()) {
        tracingBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), tracingBlock);
    }
}

void BDPExecuteOnGlobalQueue(dispatch_block_t block)
{
    if (!block) { return; }
    dispatch_block_t tracingBlock = [BDPTracingManager convertTracingBlock:block];
    if (!BDPIsMainQueue()) {
        tracingBlock();
    } else {
        dispatch_async(dispatch_get_global_queue(0, 0), tracingBlock);
    }
}

// ⚠️ Please do not use this method
// unless you know what you are doing.
void BDPExecuteOnMainQueueSync(dispatch_block_t block)
{
    if (!block) { return; }
    dispatch_block_t tracingBlock = [BDPTracingManager convertTracingBlock:block];
    if (BDPIsMainQueue()) {
        tracingBlock();
    } else {
        dispatch_sync(dispatch_get_main_queue(), tracingBlock);
    }
}

void BDPExecuteOnMainQueueOnceSync(dispatch_once_t *onceToken, dispatch_block_t block)
{
    // The solution was borrowed from a post by Ben Alpert:
    // https://benalpert.com/2014/04/02/dispatch-once-initialization-on-the-main-thread.html
    // See also: https://www.mikeash.com/pyblog/friday-qa-2014-06-06-secrets-of-dispatch_once.html
    dispatch_block_t tracingBlock = [BDPTracingManager convertTracingBlock:block];
    if (BDPIsMainQueue()) {
        dispatch_once(onceToken, tracingBlock);
    } else {
        if (DISPATCH_EXPECT(*onceToken == 0L, NO)) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                dispatch_once(onceToken, tracingBlock);
            });
        }
    }
}

NSData *BDPDecodeDataFromPath(NSString *filePath)
{
    if (BDPIsEmptyString(filePath)) {
        return nil;
    }
    
    NSError *error = nil;
    NSString *content = [NSString lss_stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        // 与 GDMonitorCode.decode_data_from_path_failed 等价，实现BDPutils 与小程序解耦
        OPMonitorCode *decodeFailedCode = [[OPMonitorCode alloc] initWithDomain:@"client.open_platform.gadget" code:10046 level:OPMonitorLevelError message:@"decode_data_from_path_failed"];
        OPErrorWithError(decodeFailedCode, error);
        return nil;
    }

    NSData *data = [[NSData alloc] initWithBase64EncodedString:content options:0];
    NSString *decodeVersion = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return data;
}

NSString *BDPCurrentNetworkType(void)
{
    BOOL isConnected = [BDPNetworking isNetworkConnected];
    BDPNetworkType type = [BDPNetworking networkType];
    NSString *typeStr = @"unknown";
    if (!isConnected) {
        typeStr = @"none";
    } else if (type & BDPNetworkTypeWifi) {
        typeStr = @"wifi";
    } else if (type & BDPNetworkType4G) {
        typeStr = @"4g";
    } else if (type & BDPNetworkType3G) {
        typeStr = @"3g";
    } else if (type & BDPNetworkType2G) {
        typeStr = @"2g";
    } else if (type & BDPNetworkTypeMobile) {
        typeStr = @"mobile";
    }
    return typeStr;
}

BOOL BDPCurrentNetworkConnected(void)
{
    return [BDPNetworking isNetworkConnected];
}
