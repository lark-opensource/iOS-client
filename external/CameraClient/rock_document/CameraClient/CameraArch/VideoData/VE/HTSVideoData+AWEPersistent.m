//
//  HTSVideoData+AWEPersistent.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/8/8.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "HTSVideoData+AWEPersistent.h"
#import <TTVideoEditor/HTSVideoData+Dictionary.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMonitorToolProtocol.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>

static const NSErrorDomain HTSVideoDataPersistDomain = @"HTSVideoData(AWEPersistent)";

@implementation HTSVideoData (AWEPersistent)

+ (BOOL)saveDictionaryToPath:(NSString *)path dict:(NSDictionary *) dict error:(NSError *__autoreleasing*)error
{
    NSParameterAssert(path);
    NSParameterAssert(dict);
    NSError *innerError;
    
    if (![NSPropertyListSerialization
          propertyList:dict
          isValidForFormat: NSPropertyListBinaryFormat_v1_0]) {
        AWELogToolError2(@"save", AWELogToolTagDraft, @"video data property list is not valid.");
        
        innerError = [NSError errorWithDomain:HTSVideoDataPersistDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey:@"The property list is not valid."}];
        if (error) {
            *error = innerError;
        }
        return (innerError != nil) ? NO:YES;
    }
    
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict
                                                              format:NSPropertyListBinaryFormat_v1_0
                                                             options:0
                                                               error:&innerError];
    if (data == nil) {
        if (error) {
            *error = innerError;
        }
        AWELogToolError2(@"save", AWELogToolTagDraft, @"data is nil. error: %@, path: %@, dict: %@", innerError, path, dict);
        return (innerError != nil) ? NO:YES;
    }
    
    BOOL writeStatus = [data writeToFile:path
                                 options:NSDataWritingAtomic
                                   error:&innerError];
    
    if (!writeStatus) {
        AWELogToolError2(@"save", AWELogToolTagDraft, @"write file failed. error: %@, path: %@, data_cnt: %zd", innerError, path, data.length);
        
        if (error) {
            *error = innerError;
        }
        
        if ([innerError.domain isEqual:NSCocoaErrorDomain] && innerError.code == NSFileWriteUnknownError) {
            [ACCMonitorTool() showWithTitle:@"Save draft error(512)"
                                      error:innerError
                                      extra:@{@"path":path}
                                      owner:@"raojunhua, yebingwei"
                                    options:ACCMonitorToolOptionModelAlert|ACCMonitorToolOptionUploadAlog|ACCMonitorToolOptionCaptureScreen];
        }
     
        
        // NSFileWriteUnknownError = 512, Write error (reason unknown)
        if ([innerError.domain isEqual:NSCocoaErrorDomain] && innerError.code == NSFileWriteUnknownError) {
            NSMutableDictionary *extraData = [@{} mutableCopy];
            NSInteger monitorStatus = 1;
            NSString *draftRootDirectoryPath = [AWEDraftUtils draftRootPath];
            BOOL draftRootIsDirectory = NO;
            if ([[NSFileManager defaultManager] fileExistsAtPath:draftRootDirectoryPath isDirectory:&draftRootIsDirectory]) {
                // 1.check disk create file error, stage:1
                BOOL pathIsDirectory = NO;
                BOOL videoDataSavePathExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&pathIsDirectory];
                AWELogToolError2(@"save", AWELogToolTagDraft, @"createFile and writeToFileFailed, path:%@, innerError:%@, errorCode = %d, errorDesc = %s, videoDataSavePathExist:%@, pathIsDirectory:%@, draftRootIsDirectory:%@", path, innerError, errno, strerror(errno), @(videoDataSavePathExist), @(pathIsDirectory), @(draftRootIsDirectory));
                extraData[@"videoDataExist"] = @(videoDataSavePathExist);
                                
                NSError *writeError = nil;
                NSNumber *writeStatus = @(0);
                extraData[@"stage"] = @(6);
                NSURL *pathUrl = [NSURL fileURLWithPath:path ?: @""];
                
                
                if (ACCConfigBool(kConfigBool_enable_remove_temps_directory)) {
                    // check MLModel super-resolution file
                    NSArray <NSString *> *tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
                    NSArray *exclusionList = ACCConfigArray(kConfigArray_cache_clean_exclusion_list);
                    for (NSString *file in tmpDirectory) {
                        if (file.length > 0 && ![exclusionList containsObject:file]) {
                            if ([file containsString:@".mlmodelc"]) {
                                NSString *dirFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:file ?: @""];
                                [[NSFileManager defaultManager] removeItemAtPath:dirFilePath error:nil];
                                //retry write data
                                extraData[@"byteCacheStatus"] = @(13);
                                if ([data writeToFile:path options:NSDataWritingAtomic error:nil]) {
                                    writeStatus = @(13);
                                } else {
                                    extraData[@"byteCacheStatus"] = @(-13);
                                }
                            } else {
                                NSString *tempDirectoryParth = NSTemporaryDirectory();
                                NSString *subDirFilePath = [tempDirectoryParth stringByAppendingPathComponent:file ?: @""];
                                BOOL isDirectory = NO;
                                BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:subDirFilePath isDirectory:&isDirectory];
                                if (fileExist && isDirectory) {
                                    NSArray <NSString *> *tmpSubDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:subDirFilePath error:NULL];
                                    for (NSString *subFileName in tmpSubDirectory) {
                                        if (subFileName.length > 0 && ![exclusionList containsObject:subFileName] && [subFileName containsString:@".mlmodelc"]) {
                                            [[NSFileManager defaultManager] removeItemAtPath:subDirFilePath error:nil];
                                            // retry Write data
                                            extraData[@"byteCacheStatus"] = @(14);
                                            if ([data writeToFile:path options:NSDataWritingAtomic error:nil]) {
                                                writeStatus = @(14);
                                            } else {
                                                extraData[@"byteCacheStatus"] = @(-14);
                                            }
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                if (writeStatus.integerValue == 0 && ACCConfigBool(kConfigBool_enable_remove_temp_directory)) {
                    // remove temp cache
                    [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) cleanUserCache];
                    if ([data writeToFile:path options:NSDataWritingAtomic error:nil]) {
                        writeStatus = @(11);
                    }
                    
                }
                    
                if (path && writeStatus.integerValue == 0) {
                    if ([data writeToFile:path options:0 error:nil]) { // No temporary file, nonatomic
                        writeStatus = @(10);
                    } else if ([data writeToFile:path options:NSDataWritingAtomic error:nil]) {
                        writeStatus = @(1);
                    } else if ([data writeToFile:path options:NSDataWritingFileProtectionNone error:nil]) { // No protection file
                        writeStatus = @(2);
                    } else if ([data writeToFile:path atomically:YES]) {
                        writeStatus = @(3);
                    } else if ([data writeToFile:path atomically:NO]) {
                        writeStatus = @(4);
                    }
                }
                
                if (pathUrl && writeStatus.integerValue == 0) {
                    if ([data writeToURL:pathUrl options:0 error:nil]) {
                        writeStatus = @(5);
                    } else if ([data writeToURL:pathUrl options:NSDataWritingFileProtectionNone error:nil]) {
                        writeStatus = @(6);
                    } else if ([data writeToURL:pathUrl options:NSDataWritingAtomic error:nil]) {
                        writeStatus = @(7);
                    } else if ([data writeToURL:pathUrl atomically:YES]) {
                        writeStatus = @(8);
                    } else if ([data writeToURL:pathUrl atomically:NO]) {
                        writeStatus = @(9);
                    }
                }
                
                extraData[@"cProtectionNoneWriteStatus"] = writeStatus;
                if (writeStatus.integerValue != 0) {
                    monitorStatus = 0;
                    if (error) {
                        *error = nil;
                    }
                    innerError = nil;
                    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
                    AWELogToolInfo2(@"save", AWELogToolTagDraft, @"draft retry write data success,writeStatus:%@, file attributes:%@",writeStatus, attributes);
                } else {
                    AWELogToolError2(@"save", AWELogToolTagDraft, @"retrySuccessStatus:%@, error:%@", writeStatus, writeError);
                }
                
                extraData[@"retryCreateFileSuccess"] = @(monitorStatus);
                
                [ACCMonitor() trackService:@"studio_check_disk_create_file" status:monitorStatus extra:extraData];
                [ACCTracker() trackEvent:@"studio_check_disk_create_file" params:extraData needStagingFlag:NO];
                
            } else {
                AWELogToolError2(@"save", AWELogToolTagDraft, @"draftRootPath is not exist, draftRootIsDirectory:%@", @(draftRootIsDirectory));
            }
        } else {
            // handle other error
        }
    }
    return (innerError != nil) ? NO:YES;
}

+ (NSDictionary *)readDictionaryFromPath:(NSString *)path error:(NSError *__autoreleasing*)error
{
    NSParameterAssert(path);
    NSError *innerError = nil;
    if (path == nil) {
        AWELogToolWarn(AWELogToolTagDraft, @"reading path %@ is nil", path);
        return nil;
    } else if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        AWELogToolWarn(AWELogToolTagDraft, @"reading file %@ not exists", path);
        innerError = [NSError errorWithDomain:HTSVideoDataPersistDomain code:-260 userInfo:@{NSLocalizedDescriptionKey:@"reading file not exists."}];
        if (error) {
            *error = innerError;
        }
        return nil;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:path
                                          options:0
                                            error:&innerError];
    if (data == nil) {
        AWELogToolError(AWELogToolTagDraft, @"error reading file %@: %@", path, innerError);
        
        if (error) {
            *error = innerError;
        }
        return nil;
    }
    
    NSDictionary *dic = [NSPropertyListSerialization propertyListWithData:data
                                                                  options:0
                                                                   format:NULL
                                                                    error:&innerError];
    if (dic == nil) {
        AWELogToolError(AWELogToolTagDraft, @"error serializing data. path:%@, error:%@, data_cnt:%zd", path, innerError, data.length);
        
        if (error) {
            *error = innerError;
        }
    }
    return  dic;
}

- (void)saveVideoDataToFileUsePropertyListSerialization:(NSString *_Nullable)filePath completion:(nullable void(^)(BOOL saved, NSError * _Nullable error))completion
{
    NSString *dirPath = [filePath stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
        NSError *error;
        BOOL succeed = [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (succeed) {
            AWELogToolInfo2(@"save", AWELogToolTagDraft, @"draft directory successful reconstruction with dirpath:%@", dirPath);
        } else {
            AWELogToolError2(@"save" ,AWELogToolTagDraft, @"draft directory error creating dirpath:%@ error:%@", dirPath, error);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(NO, error);
            });
            return;
        }
    }
    
    NSDictionary *dataDict = [[self class] readDictionaryFromPath:filePath
                                                            error:nil];
    
    NSMutableDictionary *assertUrlDic = [NSMutableDictionary dictionary];
    //    NSString *fileFolder = [filePath stringByDeletingLastPathComponent];
    if (dataDict) {
        NSArray *videoAssetUrls = ACCDynamicCast(dataDict[@"videoAssetUrls"], NSArray);
        NSArray *audioAssetUrls = ACCDynamicCast(dataDict[@"audioAssetUrls"], NSArray);
        
        for (NSString *url in videoAssetUrls) {
            assertUrlDic[url] = [NSNumber numberWithBool:YES];
        }
        for (NSString *url in audioAssetUrls) {
            assertUrlDic[url] = [NSNumber numberWithBool:YES];
        }
        
    }
    AWELogToolInfo2(@"save", AWELogToolTagDraft, @"assetUrlDict: %@", assertUrlDic);
    
    [self saveVideoDataToPath:dirPath withExistUrlDict:assertUrlDic completion:^(NSMutableDictionary * _Nullable dict, NSError * _Nullable error) {
        if (!dict && error) {
            !completion ?: completion(NO, error);
            return;
        }
        NSError *writeError;
        [[self class] saveDictionaryToPath:filePath dict:dict error:&writeError];
        if (!writeError) {
            !completion ?: completion(YES, nil);
        } else {
            AWELogToolError(AWELogToolTagDraft, @"save videoData failed %@: %@", dirPath, writeError);
            !completion ?: completion(NO, writeError);
        }
    }];
}

+ (void)loadVideoDataFromFile:(NSString *_Nullable)filePath completion:(nullable void(^)(HTSVideoData * _Nullable videoData, NSError * _Nullable error))completion
{
    __block NSError *error;
    NSDictionary *dataDict = [self readDictionaryFromPath:filePath error:&error];
    NSString *fileFolder = [filePath stringByDeletingLastPathComponent];
    if (!dataDict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            error = error ?: [NSError errorWithDomain:HTSVideoDataPersistDomain
                                                 code:0
                                             userInfo:@{NSLocalizedDescriptionKey:@"[default] error loading file"}];
            !completion ?: completion(nil, error);
        });
        return;
    }
    
    [self loadVideoDataFromDictionary:dataDict fileFolder:fileFolder completion:^(HTSVideoData * _Nullable videoData, NSError * _Nullable error) {
        !completion ?: completion(videoData, error);
    }];
}

@end
