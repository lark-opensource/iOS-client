//
//  AWECloudCommandCustom.m
//  AWECloudCommand
//
//  Created by wangdi on 2018/4/11.
//

#import "AWECloudCommandCustom.h"
#import "AWECloudCommandManager.h"
#import "NSDictionary+AWECloudCommandUtil.h"
#import "AWECloudCommandMacros.h"

@implementation AWECloudCommandCustom

AWE_REGISTER_CLOUD_COMMAND(@"custom")

+ (instancetype)createInstance
{
    return [[self alloc] init];
}

- (void)excuteCommand:(AWECloudCommandModel *)model
           completion:(AWECloudCommandResultCompletion)completion
{
    NSDictionary *params = model.params;
    AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
    result.commandId = model.commandId;
    result.fileName = @"Template.txt";
    NSTimeInterval startTimestamp = [[NSDate date] timeIntervalSince1970];
    
    NSDictionary *customDict = [params awe_cc_dictionaryValueForKey:@"template"];
    if (!customDict.count) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = @"Template should not be empty!";
        AWESAFEBLOCK_INVOKE(completion, result);
        return;
    }
    
    NSArray<Class<AWECustomCommandHandler>> *customCommandHandlerClsArray = [AWECloudCommandManager sharedInstance].customCommandHandlerClsArray;
    NSString *commandIdentidier = [customDict awe_cc_stringValueForKey:@"command"];
    id<AWECustomCommandHandler> handler = nil;
    for (Class<AWECustomCommandHandler> handlerCls in customCommandHandlerClsArray) {
        if ([[handlerCls cloudCommandIdentifier] isEqualToString:commandIdentidier]) {
            handler = [handlerCls createInstance];
            break;
        }
    }
    
    [handler excuteCommandWithParams:customDict completion:^(AWECustomCommandResult *customCommandResult) {
        if (customCommandResult.error) {
            result.status = AWECloudCommandStatusFail;
            result.errorMessage = customCommandResult.error.description;
        } else {
            result.fileType = customCommandResult.fileType.length ? customCommandResult.fileType : @"unknown";
            result.mimeType = @"text/plain";    // TODO: @shanshuo 稍后删除
            result.data = customCommandResult.data;
        }
        result.operateTimestamp = customCommandResult.operateTimestamp ?: startTimestamp;
        
        if ([handler respondsToSelector:@selector(uploadCommandResultSuccessedWithParams:)]) {
            result.uploadSuccessedBlock = ^{
                [handler uploadCommandResultSuccessedWithParams:customDict];
            };
        } else if ([handler respondsToSelector:@selector(uploadCommandResultFailedWithParams:error:)]) {
            result.uploadFailedBlock = ^(NSError * _Nonnull error) {
                [handler uploadCommandResultFailedWithParams:customDict error:error];
            };
        }
        
        AWESAFEBLOCK_INVOKE(completion, result);
    }];
}

@end
