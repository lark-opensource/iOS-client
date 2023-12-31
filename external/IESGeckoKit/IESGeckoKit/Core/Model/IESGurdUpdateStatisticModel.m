//
//  IESGurdUpdateStatisticModel.m
//  IESGeckoKit
//
//  Created by xinwen tan on 2021/10/13.
//

#import "IESGurdUpdateStatisticModel.h"

#import "IESGeckoDefines+Private.h"

@interface IESGurdUpdateStageModel ()

- (instancetype)initWithPrefix:(NSString *)prefix;
- (void)putDataToDict:(NSMutableDictionary *)dict;

@end

@implementation IESGurdUpdateStageModel

- (instancetype)initWithPrefix:(NSString *)prefix;
{
    self = [super init];
    if (self) {
        self.prefix = prefix;
    }
    return self;
}

- (void)putDataToDict:(NSMutableDictionary *)dict
{
    
    dict[[self.prefix stringByAppendingString:@"result"]] = @(self.result ? 0 : 1);
    dict[[self.prefix stringByAppendingString:@"url"]] = self.url;
    
    if (self.errMsg.length > 0) dict[[self.prefix stringByAppendingString:@"err_msg"]] = self.errMsg;
    if (self.errCode != 0) dict[[self.prefix stringByAppendingString:@"err_code"]] = @(self.errCode);
    if (self.downloadErrCode != 0) dict[[self.prefix stringByAppendingString:@"download_err_code"]] = @(self.downloadErrCode);
    if (self.failedTimes > 0)
        dict[[self.prefix stringByAppendingString:@"download_failed_times"]] = @(self.failedTimes);
}

@end

@interface IESGurdUpdateStatisticModel ()

@property (nonatomic, strong) NSMutableDictionary *stageModelDict;

@end

@implementation IESGurdUpdateStatisticModel

- (IESGurdUpdateStageModel *)getStageModel: (BOOL)needCreate
                                   isPatch: (BOOL)isPatch
{
    NSString *prefix;
    if (isPatch) {
        prefix = @"patch_";
    } else {
        prefix = @"full_";
    }
    if (needCreate) {
        if (self.stageModelDict == nil) {
            self.stageModelDict = [NSMutableDictionary dictionary];
            // 这里认为是第一个阶段，第一个阶段的开始时间当成整个更新开始的时间
            self.startTime = [NSDate date];
        }
        self.stageModelDict[prefix] = [[IESGurdUpdateStageModel alloc] initWithPrefix:prefix];
    }
    return self.stageModelDict[prefix];
}

- (void)resetDuration
{
    self.durationDownloadLastTime = 0;
    self.durationDownload = 0;
    self.durationActive = 0;
    self.durationUnzip = 0;
    self.durationDecompressZstd = 0;
    self.durationBytepatch = 0;
    self.durationZipPatch = 0;
}

- (void)putDataToDict:(NSMutableDictionary *)dict
{
    dict[@"update_result"] = @(self.updateResult ? 0 : 1);
    dict[@"download_type"] = @(self.downloadType);
    dict[@"dur_wait_download"] = @((int)([self.startTime timeIntervalSinceDate:self.createTime] * 1000));
    
    if (self.createByReboot) dict[@"create_by_reboot"] = @(1);
    if (self.patchID > 0) dict[@"patch_id"] = @(self.patchID);
    
    if (self.durationTotal > 0) dict[@"dur_total"] = @(self.durationTotal);
    if (self.durationLastStage > 0) dict[@"dur_last_stage"] = @(self.durationLastStage);
    if (self.durationDownload > 0) dict[@"dur_download"] = @(self.durationDownload);
    if (self.durationDownloadLastTime > 0) dict[@"dur_download_last_time"] = @(self.durationDownloadLastTime);
    if (self.durationActive > 0) dict[@"dur_active"] = @(self.durationActive);
    if (self.durationUnzip > 0) dict[@"dur_unzip"] = @(self.durationUnzip);
    if (self.durationDecompressZstd > 0) dict[@"dur_decompress_zstd"] = @(self.durationDecompressZstd);
    if (self.durationBytepatch > 0) dict[@"dur_bytepatch"] = @(self.durationBytepatch);
    if (self.durationZipPatch > 0) dict[@"dur_zip_patch"] = @(self.durationZipPatch);
    
    for (IESGurdUpdateStageModel *model in self.stageModelDict.allValues) {
        [model putDataToDict:dict];
    }
}

@end
