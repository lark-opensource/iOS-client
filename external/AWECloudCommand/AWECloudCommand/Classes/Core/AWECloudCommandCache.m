//
//  AWECloudCommandCache.m
//  Pods
//
//  Created by willorfang on 2017/1/23.
//
//

#import "AWECloudCommandCache.h"
#import "AWECloudDiskUtility.h"
#import "AWECloudCommandMacros.h"
#import "AWECloudCommandManager.h"

@implementation AWECloudCommandCache

AWE_REGISTER_CLOUD_COMMAND(@"disk")

+ (instancetype)createInstance
{
    return [[self alloc] init];
}

- (void)excuteCommand:(AWECloudCommandModel *)model completion:(AWECloudCommandResultCompletion)completion
{
    AWECloudCommandResult *result = [self _resultWithCommand:model];
    AWESAFEBLOCK_INVOKE(completion, result);
}

- (AWECloudCommandResult *)_resultWithCommand:(AWECloudCommandModel *)model
{
    AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
    result.fileName = @"Cache.txt";
    result.fileType = @"log_dir_tree";
    result.commandId = model.commandId;
    result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
    
    // 命令参数解析
    NSDictionary *params = model.params;
    NSString *dir = [params objectForKey:@"dir"];
    if (!dir) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = @"dir should not be empty!";
        return result;
    }
    
    NSString *absoluteDirPath = [NSHomeDirectory() stringByAppendingPathComponent:dir];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = YES;
    BOOL isExist = [fileManager fileExistsAtPath:absoluteDirPath isDirectory:&isDirectory];
    if (!isExist) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = [dir stringByAppendingString:@" not found!"];
        return result;
    }
    if (!isDirectory) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = [dir stringByAppendingString:@" is not a file directory!"];
        return result;
    }
    
    // data
    NSDictionary *dataDict = [self _detailInfoUnderPath:absoluteDirPath];
    
    result.mimeType = @"text/plain";
    result.data = [NSJSONSerialization dataWithJSONObject:dataDict options:NSJSONWritingPrettyPrinted error:nil];
    
    return result;
}


- (NSDictionary *)_detailInfoUnderPath:(NSString *)path
{
    AWECloudCommandCustomBlock handler = [AWECloudCommandManager sharedInstance].diskPathsComplianceHandler;
    BOOL complianceMatched = false;
    if (handler) {
        AWECloudCommandModel *model = [[AWECloudCommandModel alloc] init];
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setValue:path forKey:@"path"];
        
        model.params = params;
        AWECloudCommandModel *resultModel = handler(model);
        NSNumber *complianceMatchedNum = [resultModel.params objectForKey:@"complianceMatched"];
        complianceMatched = [complianceMatchedNum boolValue];
    }
    return [self _detailInfoUnderPath:path complianceMatched:complianceMatched];
}

- (NSDictionary *)_detailInfoUnderPath:(NSString *)path complianceMatched:(BOOL)complianceMatched
{
    AWECloudCommandCustomBlock handler = [AWECloudCommandManager sharedInstance].diskPathsComplianceHandler;
    
    NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];
    NSArray<NSString *> *contentArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    [contentArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *absolutePath = [path stringByAppendingPathComponent:obj];
        //
        BOOL isDictionary = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&isDictionary];
        //
        BOOL complianceMatchedCur = false;
        if (handler) {
            AWECloudCommandModel *model = [[AWECloudCommandModel alloc] init];
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            [params setValue:absolutePath forKey:@"path"];
            [params setValue:@(complianceMatched) forKey:@"complianceMatched"];
            [params setValue:path forKey:@"compliancePrefix"];
            model.params = params;
            AWECloudCommandModel *resultModel = handler(model);
            obj = [resultModel.params objectForKey:@"path"];
            obj = [obj substringFromIndex:path.length + 1];
            if ([[dataDict allKeys] containsObject:obj]) {
                obj = [NSString stringWithFormat:@"%@_%lu", obj, (unsigned long)idx];
            }
            
            NSNumber *complianceMatchedNum = [resultModel.params objectForKey:@"complianceMatched"];
            complianceMatchedCur = [complianceMatchedNum boolValue];
        }
        long long fileSize = 0;
        if (isDictionary) {
            [dataDict setObject:[self _detailInfoUnderPath:absolutePath complianceMatched:complianceMatchedCur] forKey:obj];
        } else {
            fileSize = [AWECloudDiskUtility fileSizeAtPath:absolutePath];
            [dataDict setObject:@(fileSize) forKey:obj];
        }
    }];
    
    return [dataDict copy];
}

@end
