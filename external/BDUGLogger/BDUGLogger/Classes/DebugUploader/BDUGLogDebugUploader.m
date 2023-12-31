//
//  BDUGLogDebugUploader.m
//  Pods
//
//  Created by shuncheng on 2019/6/18.
//

#import "BDUGLogDebugUploader.h"
#import "HMDLogUploader.h"
#import "BDUGNetworkUtils.h"

@implementation BDUGLogDebugUploader

+ (instancetype)sharedInstance
{
    static BDUGLogDebugUploader *ins;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ins = [[BDUGLogDebugUploader alloc] init];
    });
    return ins;
}

- (void)uploadWithTag:(NSString *)tag andCallback:(BDUGLogDebugUploaderCallback)callback
{
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    // Wi-Fi 情况下，上传三天，其他情况上传一天
    NSInteger dayCount = BDUGNetworkWifiConnected() ? 3 : 1;
    NSTimeInterval startTime = now - dayCount * 24 * 60 * 60;
    [[HMDLogUploader sharedInstance] reportALogWithFetchStartTime:startTime
                                                     fetchEndTime:now
                                                            scene:tag
                                               reportALogCallback:callback];
}

@end
