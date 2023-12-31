//
//  AWEWaterMarkDownloader.m
//  AWEStudio-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/5/22.
//

#import "AWEWaterMarkDownloader.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <BDWebImage/BDWebImageManager.h>

@implementation AWEWaterMarkDownloader

+ (void)startDownloadWithTaskId:(NSString *)taskId effectId:(NSString *)effectId imageURLString:(NSString *)URLString completion:(AWEWaterMarkCompletionBlock)completionBlock
{
    void (^saveBlock)(NSData *imageData) = ^(NSData *imageData){
        NSString *filePath = [self imagePathWithTaskId:taskId effectId:effectId];
        if (!filePath) {
            NSError *error = [NSError errorWithDomain:@"AWEWaterMarkDownloader" code:-2 userInfo:nil];
            ACCBLOCK_INVOKE(completionBlock, nil, error);
            return;
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            ACCBLOCK_INVOKE(completionBlock, filePath, nil);
            return;
        }
        NSError *error = nil;
        BOOL success = [imageData acc_writeToFile:filePath options:NSDataWritingWithoutOverwriting error:&error];
        ACCBLOCK_INVOKE(completionBlock, (success ? filePath : nil), error);
    };
    
    NSURL *imageURL = [NSURL URLWithString:URLString];
    if (imageURL && taskId.length > 0 && effectId.length > 0) {
        BDWebImageManager *manager = [BDWebImageManager sharedManager];
        NSString *key = [manager requestKeyWithURL:imageURL];
        [[BDImageCache sharedImageCache] imageDataForKey:key withBlock:^(NSData *imageData) {
            if (imageData) {
                saveBlock(imageData);
            } else {
                [manager requestImage:imageURL alternativeURLs:nil options:0 cacheName:nil transformer:nil progress:nil complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                    [[BDImageCache sharedImageCache] imageDataForKey:key withBlock:^(NSData *imageData) {
                        
                        NSMutableDictionary *param = [@{@"uri" : [imageURL lastPathComponent] ? : @""} mutableCopy];
                        if (error) {
                            NSString *errorInfo = [NSString stringWithFormat:@"error domain: %@, code: %@, descript: %@", error.domain, @(error.code), error.description];
                            [param setObject:[NSString stringWithFormat:@"effectId: %@, error: %@", effectId, errorInfo] forKey:@"exception"];
                        }
                        
                        [ACCMonitor() trackService:@"effect_watermark_download_rate" status:imageData ? 0 : 1  extra:param.copy];
                        
                        if (imageData) {
                            saveBlock(imageData);
                        } else {
                            ACCBLOCK_INVOKE(completionBlock, nil, error);
                        }
                    }];
                }];
            }
        }];
    } else {
        NSError *error = [NSError errorWithDomain:@"AWEWaterMarkDownloader" code:-1 userInfo:nil];
        ACCBLOCK_INVOKE(completionBlock, nil, error);
    }
}

+ (NSString *)imagePathWithTaskId:(NSString *)taskId effectId:(NSString *)effectId
{
    NSString *draftPath = [AWEDraftUtils generateDraftFolderFromTaskId:taskId];
    if (!draftPath) {
        return nil;
    }
    
    if (effectId.length < 1) {
        return nil;
    }
    
    return [draftPath stringByAppendingPathComponent:[NSString stringWithFormat:@"effect_%@_watermark.png", effectId]];
}

@end
