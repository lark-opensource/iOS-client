//
//  BDUGShareFileManager.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/7/4.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

static NSString *const kBDUGShareFileResource = @"kBDUGShareFileResource";

#define BDUG_SHARE_FILE_LOCAL_PATH_FOLDER [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:@"/"] stringByAppendingString:kBDUGShareFileResource]

#define BDUG_SHARE_FILE_LOCAL_PATH(fileName) [[BDUG_SHARE_FILE_LOCAL_PATH_FOLDER stringByAppendingString:@"/"] stringByAppendingString:fileName]

#import "BDUGShareFileManager.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareEvent.h"

@implementation BDUGShareFileManager

+ (void)getFileFromURLStrings:(NSArray <NSString *> *)URLStrings
                     fileName:(NSString *)fileName
             downloadProgress:(BDUGFileDownloaderProgress)downloadProgress
                   completion:(BDUGFileDownloaderCompletion)completion
{
    //增加loading和process功能。
    if (![[NSFileManager defaultManager] fileExistsAtPath:BDUG_SHARE_FILE_LOCAL_PATH_FOLDER]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:BDUG_SHARE_FILE_LOCAL_PATH_FOLDER withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *localPath = BDUG_SHARE_FILE_LOCAL_PATH(fileName);
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        //如果已经下载过，直接使用。
        !completion ?: completion(nil, localPath);
    } else {
        [[BDUGShareAdapterSetting sharedService] shareAbilityShowLoading];
        [[BDUGFileDownloader sharedInstance] downloadFileWithURLs:URLStrings downloadPath:localPath downloadProgress:downloadProgress completion:^(NSError *error, NSString *filePath) {
            [[BDUGShareAdapterSetting sharedService] shareAbilityHideLoading];
            !completion ?: completion(error, filePath);
            NSNumber *status;
            if (!error) {
                status = @(0);
            } else if (error.code == -999) {
                //用户取消
                status = @(2);
            } else {
                //下载失败
                status = @(1);
            }
            [BDUGShareEventManager trackService:kShareMonitorFileDownload metric:nil
                                       category:@{@"status" : status,
                                                  @"url" : URLStrings.firstObject
                                       } extra:nil];
        }];
    }
}

@end
