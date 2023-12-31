//
//  AWECloudCommandNetwork.m
//  Pods
//
//  Created by willorfang on 2017/1/23.
//
//

#import "AWECloudCommandNetwork.h"
#import "AWECloudCommandNetDiagnoseManager.h"
#import "AWECloudCommandManager.h"
#import "NSString+AWECloudCommandUtil.h"
#import "AWECloudCommandMacros.h"

@implementation AWECloudCommandNetwork

AWE_REGISTER_CLOUD_COMMAND(@"network")

+ (instancetype)createInstance
{
    return [[self alloc] init];
}

- (void)excuteCommand:(AWECloudCommandModel *)model completion:(AWECloudCommandResultCompletion)completion
{
    AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
    result.fileName = @"Network.txt";
    result.fileType = @"text";
    result.commandId = model.commandId;
    result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
    // 命令参数解析
    NSDictionary *params = model.params;
    NSString *domain = [params objectForKey:@"domain"];
    AWECloudCommandNetDiagnoseManager *manager = [[AWECloudCommandNetDiagnoseManager alloc] init];
    manager.testHost = domain;
    manager.deviceId = [AWECloudCommandManager sharedInstance].cloudCommandParamModel.deviceId;
    manager.userId = [AWECloudCommandManager sharedInstance].cloudCommandParamModel.userId;
    [manager startNetDiagnoseWithCompletionBlock:^(NSString *text) {
        result.mimeType = @"text/plain";
        result.data = [text dataUsingEncoding:NSUTF8StringEncoding];
        AWESAFEBLOCK_INVOKE(completion, result);
    }];
}

@end

