//
//  TTVideoEngineExtraInfo.m
//  Pods
//
//  Created by thq on 2018/7/10.
//

#import "TTVideoEngineExtraInfo.h"
#import "TTVideoEngineUtil.h"
static dispatch_queue_t extraInfoQueue;
static id<TTVideoEngineExtraInfoProtocol> extraInfoProtocol = nil;
static long long sumData;
static NSTimeInterval firstDataTime;
static dispatch_queue_t getExtraInfoQueue() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        extraInfoQueue = dispatch_queue_create("vclould.engine.extraInfo.queue", DISPATCH_QUEUE_SERIAL);
    });
    return extraInfoQueue;
}

@implementation TTVideoEngineExtraInfo

+ (void)configExtraInfoProtocol:(id<TTVideoEngineExtraInfoProtocol>)protocol {
    extraInfoProtocol = protocol;
}

@end
void extraInfoCallback(void* user,int code,int64_t parameter1,int64_t parameter2) {
    dispatch_async(getExtraInfoQueue(), ^{
        if (sumData == 0) {
            firstDataTime = [[NSDate date] timeIntervalSince1970];
        }
        sumData += parameter1;
        if (sumData >= 50 * 1024 && extraInfoProtocol) {
            NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] - firstDataTime;
            [extraInfoProtocol speedWithDataLength:sumData interval:interval];
            sumData = 0;
        }
        
    });
}


