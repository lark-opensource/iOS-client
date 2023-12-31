//
//  AWEDraftUtils.h
//  Aweme
//
//  Created by Liu Bing on 3/5/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const AWEDraftDirectoryFlag;

@interface AWEDraftUtils : NSObject

+ (NSString *)generateTaskID;
+ (NSString *)generateDraftTrackID;
+ (NSString *)generatePathFromTaskId:(NSString *)taskID name:(NSString *)name;
+ (NSString *)generateDraftPathFromTaskId:(NSString *)taskID;
+ (NSString *)generateCoverPathFromTaskId:(NSString *)taskID;
+ (NSString *)generateCoverPathFromTaskId:(NSString *)taskID withPartIndexInAutoSpllit:(NSInteger)partIndex;
+ (NSString *)generateCoverTextPathFromTaskId:(NSString *)taskID;
+ (NSString *)generateCropCoverPathFromTaskId:(NSString *)taskID;
+ (NSString *)generateMeteorModeCoverPathFromTaskID:(NSString *)taskID;
+ (NSString *)generateBackupCoverPathFromTaskID:(NSString *)taskID;
+ (NSString *)generateTextImagePathFromTaskId:(NSString *)taskID withDraftTag:(NSString *)draftTag index:(NSInteger)index;
+ (NSString *)generateCoverTextPathFromTaskId:(NSString *)taskID withPartIndexInAutoSplit:(NSInteger)partIndex;
+ (NSString *)generateSocialPathFromTaskId:(NSString *)taskID draftTag:(NSString *)draftTag index:(NSInteger)index;
+ (NSString *)generateGrootPathFromTaskId:(NSString *)taskID draftTag:(NSString *)draftTag  index:(NSInteger)index;
+ (NSString *)generateStickerPhotoFilePathFromTaskId:(NSString *)taskID name:(NSString *)fileName;
+ (NSString *)generateCpaturedPhotoPathFromTaskId:(NSString *)taskID;
+ (NSString *)generateCpaturedOriginalPhotoPathFromTaskId:(NSString *)taskID;
+ (NSString *)generateFirstFramePathFromTaskId:(NSString *)taskID;
+ (NSString *)generateToBeUploadedImagePathFromTaskId:(NSString *)taskID;
+ (NSString *)generateToBeUploadedImageJPEGPathFromTaskId:(NSString *)taskID;
+ (NSString *)generateRandomImagePathFromTaskId:(NSString *)taskID;
+ (NSString *)generateDraftFolderFromTaskId:(NSString *)taskID;
// To avoid cover the original draft data, you should generate another path when edit from draft
+ (NSString *)generateName:(NSString *)name withDraftTag:(NSString *)draftTag;
+ (NSString *)strongBeatPathForMusic:(NSString *)musicId taskId:(NSString *)taskID;

+ (NSString *)draftInstallId;
+ (NSString *)draftRootPath;

+ (NSString *)stickerImageName;

/// Get relative path
///@ param path absolute path
+ (NSString *)relativePathFrom:(NSString *)path taskID:(NSString *)taskID;

+ (NSURL *)draftFileURLFrom:(NSString *)path taskID:(NSString *)taskID;

/// Get absolute path
///@ param path relative path
+ (NSString *)absolutePathFrom:(NSString *)path taskID:(NSString *)taskID;
+ (UIImage *)composedCoverImageFromTaskId:(NSString *)taskID coverText:(BOOL)coverText size:(CGSize)size;

+ (NSString *_Nullable)generateModernTextImagePathFromTaskId:(NSString *_Nullable)taskID index:(NSInteger)index;
+ (NSString *_Nullable)generateModernSocialPathFromTaskId:(NSString *_Nullable)taskID index:(NSInteger)index;
@end
