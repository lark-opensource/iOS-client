//
//  HMDCloudCommandFileDelete.m
//  Heimdallr-iOS13.0
//
//  Created by zhangxiao on 2019/12/11.
//

#import "HMDCloudCommandFileDelete.h"
#import "NSDictionary+HMDSafe.h"

@implementation HMDCloudCommandFileDelete

AWE_REGISTER_CLOUD_COMMAND(@"slardar_delete_file");

/// 自定义命令标识
+ (NSString *)cloudCommandIdentifier {
    return @"slardar_delete_file";
}

+ (nonnull instancetype)createInstance { 
    return [[HMDCloudCommandFileDelete alloc] init];
}

- (void)excuteCommand:(AWECloudCommandModel *)model completion:(AWECloudCommandResultCompletion)completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *deleteFilePaths = [model.params hmd_objectForKey:@"paths" class:NSArray.class];

        [self removeFilesWithRelativePaths:deleteFilePaths completion:^(BOOL success, NSArray * _Nullable results) {

            AWECloudCommandResult *commandResult = [[AWECloudCommandResult alloc] init];
            commandResult.commandId = model.commandId;
            commandResult.operateTimestamp = [[NSDate date] timeIntervalSince1970];
            if (success) {
                @try {
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"result" : results?:@[]} options:NSJSONWritingPrettyPrinted error:nil];
                    commandResult.data = jsonData;
                    commandResult.fileType = @"json";
                    commandResult.fileName = @"slardar_delete_file_log";
                    commandResult.mimeType = @"application/json";
                    commandResult.fileType = @"log_delete_file";
                } @catch (NSException *exception) {

                }
                commandResult.status = AWECloudCommandStatusSucceed;
            } else {
                commandResult.status = AWECloudCommandStatusFail;
                commandResult.errorMessage = @"paths can not be nil or empty";
            }

            if (completion) {
                completion(commandResult);
            }
        }];
    });
}

- (void)removeFilesWithRelativePaths:(NSArray<NSString *> *)relativePaths completion:(void (^)(BOOL success , NSArray * _Nullable results))completion {
    if (!relativePaths || relativePaths.count == 0) {
        if (completion) { completion(NO, nil);}
        return;
    }

    NSMutableArray *resultArray = [NSMutableArray array];
    for (NSString *singlePath in relativePaths) {
        if (![singlePath isKindOfClass:NSString.class]) { continue; }
        NSString *absolutePath = [NSHomeDirectory() stringByAppendingPathComponent:singlePath];
        BOOL isDirectory = NO;
        BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&isDirectory];
        if (!exist) {
            [resultArray addObject:@{singlePath:@"file not exit"}];
            continue;
        }
        BOOL isDeletable = [[NSFileManager defaultManager] isDeletableFileAtPath:absolutePath];
        if (!isDeletable) {
            [resultArray addObject:@{singlePath:@"file can not delete"}];
            continue;
        }
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:absolutePath error:&error];
        if (error) {
            [resultArray addObject:@{singlePath:[NSString stringWithFormat:@"file delete error: %@", error.description]}];
        } else {
            [resultArray addObject:@{singlePath: @"delete success"}];
        }
    }

    if (completion) { completion(YES, resultArray);}
}


@end
