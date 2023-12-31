//
//  AWEDraftUtils.m
//  Aweme
//
//  Created by Liu Bing on 3/5/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import "AWEDraftUtils.h"
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/UIImage+ACC.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>

NSString * const AWEDraftDirectoryFlag = @"/Documents/drafts";

@implementation AWEDraftUtils

+ (NSString *)generateTaskID
{
    return [[self dateFormatter] stringFromDate:[NSDate date]];
}

+ (NSString *)generateDraftTrackID
{
    NSString *deviceID = [ACCTracker() deviceID];
    if (!deviceID) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        deviceID = [uuid stringByReplacingOccurrencesOfString:@"-" withString:@""];
    }
    NSString *trackID = [NSString stringWithFormat:@"%@%@", deviceID, [self generateTaskID]];
    
    return trackID;
}

+ (NSString *)generatePathFromTaskId:(NSString *)taskID name:(NSString *)name
{
    if (!taskID || !name) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    
    return [draftFolder stringByAppendingPathComponent:name]; // File address
}

+ (NSString *)generateDraftPathFromTaskId:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }

    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    
    return [draftFolder stringByAppendingPathComponent:taskID]; // Draft information file address
}

+ (NSString *)generateCoverPathFromTaskId:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    
    return [draftFolder stringByAppendingPathComponent:@"cover.jpeg"]; // Draft cover image file address
}

+ (NSString *)generateCropCoverPathFromTaskId:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    return [draftFolder stringByAppendingPathComponent:@"crop_cover.png"];
}

+ (NSString *)generateMeteorModeCoverPathFromTaskID:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    return [draftFolder stringByAppendingPathComponent:@"meteor_mode_cover.png"];
}

+ (NSString *)generateBackupCoverPathFromTaskID:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    return [draftFolder stringByAppendingPathComponent:@"backup_cover.png"];
}

+ (NSString *)generateCoverTextPathFromTaskId:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    
    return [draftFolder stringByAppendingPathComponent:@"cover_text.png"]; // Draft cover text image file address
}

+ (NSString *)generateTextImagePathFromTaskId:(NSString *)taskID withDraftTag:(NSString *)draftTag index:(NSInteger)index
{
    if (!taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    
    return [draftFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.png",[AWEDraftUtils generateName:@"text" withDraftTag:draftTag],@(index)]]; // Text sticker address
}

+ (NSString *)generateSocialPathFromTaskId:(NSString *)taskID draftTag:(NSString *)draftTag  index:(NSInteger)index
{
    if (!taskID) {
        return nil;
    }
       
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    // social( mention/hashtag) sticker
    return [draftFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.png", [AWEDraftUtils generateName:@"social" withDraftTag:draftTag], @(index)]];
}

+ (NSString *)generateGrootPathFromTaskId:(NSString *)taskID draftTag:(NSString *)draftTag  index:(NSInteger)index
{
    if (!taskID) {
        return nil;
    }
       
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    // groot sticker
    return [draftFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.png", [AWEDraftUtils generateName:@"groot" withDraftTag:draftTag], @(index)]];
}

+ (NSString *)generateToBeUploadedImagePathFromTaskId:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    return [draftFolder stringByAppendingPathComponent:@"toBeUploadImage.png"]; // Image file address optimized for quick photo experience
}

+ (NSString *)generateToBeUploadedImageJPEGPathFromTaskId:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    return [draftFolder stringByAppendingPathComponent:@"toBeUploadImage.jpeg"];
}

+ (NSString *)generateRandomImagePathFromTaskId:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    return [draftFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [[NSUUID UUID] UUIDString]]];
}

+ (NSString *)generateFirstFramePathFromTaskId:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    
    return [draftFolder stringByAppendingPathComponent:@"firstFrame.jpeg"]; // Draft first frame picture file address
}

+ (NSString *)generateDraftFolderFromTaskId:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    
    // To start protected security mode cleanup, you need to keep the draft and draft user associated databases
    // Therefore, if there is any change in the path of these two files, or if there is a new database or folder related to the draft, please inform zhufeng.llvm or Quanquan
    // - Documents/Aweme.db
    // - Documents/drafts
    // The folder here is: documents / drafts/
    NSString *draftRootDirectoryPath = [AWEDraftUtils draftRootPath];
    NSString *draftFolder = [draftRootDirectoryPath stringByAppendingPathComponent:taskID];
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:draftFolder isDirectory:&isDirectory]) {
        NSError *createDirectoryError;
        [[NSFileManager defaultManager] createDirectoryAtPath:draftFolder
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&createDirectoryError];
        if (createDirectoryError) {
            NSError *attributeError;
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:draftRootDirectoryPath error:&attributeError];
            AWELogToolError2(@"save", AWELogToolTagDraft, @"draft root directory attributes:%@, isDirectory:%@, failed with attributeError:%@, createDirectoryError:%@", attributes, @(isDirectory), attributeError, createDirectoryError);
        }
    }
    return draftFolder;// A single draft directory, which stores draft information files and related video and audio files
}

+ (NSString *)strongBeatPathForMusic:(NSString *)musicId taskId:(NSString *)taskID
{
    if (!musicId || !taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    NSString *filename = [musicId stringByAppendingString:@"_strongbeat.json"];
    NSString *localPath = [draftFolder stringByAppendingPathComponent:filename];
    
    return localPath;
}

+ (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"zh-CN"]];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"]];
        [_dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    });
    
    return _dateFormatter;
}

+ (NSString *)draftInstallId
{
    static NSString *installId = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *key = @"com.acc.draft.installId";
        installId = [ACCCache() stringForKey:key];
        if (!installId) {
            installId = [[self dateFormatter] stringFromDate:[NSDate date]];
            [ACCCache() setObject:installId forKey:key];
        }
    });
    
    return installId;
}

+ (NSString *)draftRootPath
{
    NSString *draftFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    draftFolder = [draftFolder stringByAppendingPathComponent:@"drafts"];
    return draftFolder;
}

+ (NSString *)generateStickerPhotoFilePathFromTaskId:(NSString *)taskID name:(NSString *)fileName
{
    if (!taskID) {
        return nil;
    }
    if (!fileName) {
        return nil;
    }
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    return [draftFolder stringByAppendingPathComponent:fileName];
}

+ (NSString *)generateCpaturedPhotoPathFromTaskId:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    return [draftFolder stringByAppendingPathComponent:@"captured_photo.jpeg"];
}

+ (NSString *)generateCpaturedOriginalPhotoPathFromTaskId:(NSString *)taskID
{
    if (!taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    return [draftFolder stringByAppendingPathComponent:@"captured_original_photo.jpeg"];
}

+ (NSString *)stickerImageName
{
    NSString *suffix = [[self dateFormatter] stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"sticker_save_photo_%@.png", suffix];
}

+ (NSString *)generateName:(NSString *)name withDraftTag:(NSString *)draftTag
{
    if (draftTag.length) {
        return [NSString stringWithFormat:@"%@_%@",draftTag,name];
    }
    return name;
}

+ (NSString *)pathFromTaskID:(NSString *)taskID relpath:(NSString *)relpath
{
    if (taskID == nil || relpath == nil) {
        return nil;
    }
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    return [draftFolder stringByAppendingPathComponent:relpath];
}

+ (NSString *)relativePathFrom:(NSString *)path taskID:(NSString *)taskID
{
    if (path == nil || path.length == 0) {
        return nil;
    }
    if (taskID == nil || taskID.length == 0) {
        return nil;
    }
    
    NSString *flagPath = [AWEDraftDirectoryFlag stringByAppendingPathComponent:taskID];
    NSRange range = [path rangeOfString:flagPath];
    if (range.location != NSNotFound && range.length != NSNotFound) {
        NSString *relatePath = [path substringFromIndex:(range.location + range.length)];
        return relatePath;
    }
    return path;
}

+ (NSURL *)draftFileURLFrom:(NSString *)path taskID:(NSString *)taskID
{
    if (path == nil || path.length == 0) {
        return nil;
    }
    if (taskID == nil || taskID.length == 0) {
        return nil;
    }
    
    NSURL *url = nil;
    NSString *baseURL = nil;
    NSString *relativeURL = nil;
    
    NSString *flagPath = [AWEDraftDirectoryFlag stringByAppendingPathComponent:taskID];
    NSRange range = [path rangeOfString:flagPath];
    if (range.location != NSNotFound && range.length != NSNotFound) {
        relativeURL = [path substringFromIndex:(range.location + range.length + 1)];
        baseURL = [path substringToIndex:(range.location + range.length + 1)];
    }
    
    if (baseURL && relativeURL) {
        url = [NSURL fileURLWithPath:relativeURL relativeToURL:[NSURL fileURLWithPath:baseURL]];
    } else {
        url = [NSURL fileURLWithPath:path];
    }
    
    return url;
}

+ (NSString *)absolutePathFrom:(NSString *)path taskID:(NSString *)taskID
{
    if (path == nil || path.length == 0) {
        return nil;
    }
    if (taskID == nil || taskID.length == 0) {
        return path;
    }
    
    NSString *relatePath = [self relativePathFrom:path taskID:taskID];
    if (relatePath == nil) {
        relatePath = path;
    }
    
    NSString *draftPrefixPath =  [self generateDraftFolderFromTaskId:taskID];
    return [draftPrefixPath stringByAppendingPathComponent:relatePath];
}

+ (UIImage *)composedCoverImageFromTaskId:(NSString *)taskID coverText:(BOOL)coverText size:(CGSize)size
{
    if (!taskID) {
        return nil;
    }
    
    if (size.width > 0 && size.height > 0) {
        UIImage *coverImage = [UIImage downsampledImageWithSize:size sourcePath:[self generateCropCoverPathFromTaskId:taskID]];
        if (!coverImage) {
            coverImage = [UIImage downsampledImageWithSize:size sourcePath:[self generateCoverPathFromTaskId:taskID]];
        }
        if (!coverImage) {
            coverImage = [UIImage downsampledImageWithSize:size sourcePath:[self generateBackupCoverPathFromTaskID:taskID]];
        }
        
        if (coverText) {
            return [UIImage acc_composeImage:coverImage withImage:[UIImage downsampledImageWithSize:size sourcePath:[self generateCoverTextPathFromTaskId:taskID]]];
        }
        return coverImage;
        
    } else {
        UIImage *coverImage = [UIImage imageWithContentsOfFile:[self generateCropCoverPathFromTaskId:taskID]];
        if (!coverImage) {
            coverImage = [UIImage imageWithContentsOfFile:[self generateCoverPathFromTaskId:taskID]];
        }
        if (!coverImage) {
            coverImage = [UIImage imageWithContentsOfFile:[self generateBackupCoverPathFromTaskID:taskID]];
        }
        
        if (coverText) {
            return [UIImage acc_composeImage:coverImage withImage:[UIImage imageWithContentsOfFile:[self generateCoverTextPathFromTaskId:taskID]]];
        }
        return coverImage;
    }
}

+ (NSString *)generateCoverPathFromTaskId:(NSString *)taskID withPartIndexInAutoSpllit:(NSInteger)partIndex
{
    if (!taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    NSString* imageName = [NSString stringWithFormat:@"cover_part_%li.jpeg",partIndex];
    return [draftFolder stringByAppendingPathComponent:imageName]; // Draft cover image file address
}

+ (NSString *)generateCoverTextPathFromTaskId:(NSString *)taskID withPartIndexInAutoSplit:(NSInteger)partIndex
{
    if (!taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    NSString* imageName = [NSString stringWithFormat:@"cover_text_part_%li.png",partIndex];
    return [draftFolder stringByAppendingPathComponent:imageName]; // Draft cover text image file address
}

+ (NSString *_Nullable)generateModernSocialPathFromTaskId:(NSString *_Nullable)taskID index:(NSInteger)index
{
    if (!taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    
    return [draftFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.png",[AWEDraftUtils generateName:@"social" withDraftTag:[NSUUID UUID].UUIDString],@(index)]];
}

+ (NSString *_Nullable)generateModernTextImagePathFromTaskId:(NSString *_Nullable)taskID index:(NSInteger)index
{
    if (!taskID) {
        return nil;
    }
    
    NSString *draftFolder = [self generateDraftFolderFromTaskId:taskID];
    
    return [draftFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.png",[AWEDraftUtils generateName:@"text" withDraftTag:[NSUUID UUID].UUIDString],@(index)]]; // Text sticker address
}


@end
