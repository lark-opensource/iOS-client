//
//  ACCSecurityFramesSaver.m
//  AWEStudioService-Pods-Aweme
//
//  Created by lixingdong on 2021/3/31.
//

#import "ACCSecurityFramesSaver.h"
#import <CreativeKit/UIImage+ACCAdditions.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogProtocol.h>

@implementation ACCSecurityFramesSaver

+ (dispatch_queue_t)securitySaveQueue
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.AWEStudio.queue.securitySave", DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

+ (void)saveImage:(UIImage *)frame
             type:(ACCSecurityFrameType)type
           taskId:(NSString *)taskId
       completion:(void (^)(NSString *path, BOOL success, NSError *error))completion
{
    [self saveImage:frame type:type taskId:taskId compressed:YES completion:completion];
}

+ (void)saveImages:(NSArray<UIImage *> *)frames
              type:(ACCSecurityFrameType)type
            taskId:(NSString *)taskId
        completion:(void (^)(NSArray<NSString *> *paths, BOOL success, NSError *error))completion
{
    [self saveImages:frames type:type taskId:taskId compressed:YES completion:completion];
}

+ (void)saveImage:(UIImage *)frame
             type:(ACCSecurityFrameType)type
           taskId:(NSString *)taskId
       compressed:(BOOL)compressed
       completion:(void (^)(NSString *path, BOOL success, NSError *error))completion
{
    acc_dispatch_queue_async_safe([self securitySaveQueue], ^{
        @autoreleasepool {
            __block NSString *path = [self p_framePathWithTaskId:taskId compressed:compressed type:type];
            
            UIImage *image;
            NSData *imageData;
            if (compressed) {
                image = [UIImage acc_tryCompressImage:frame ifImageSizeLargeTargetSize:[ACCSecurityFramesUtils framesResolution]];
                imageData = UIImageJPEGRepresentation(image, [ACCSecurityFramesUtils framesCompressionRatio]);
            } else {
                image = frame;
                imageData = UIImageJPEGRepresentation(image, 1.0);
            }
                
            NSError *writeError;
            BOOL success = [imageData acc_writeToFile:path options:NSDataWritingAtomic error:&writeError];
            
            acc_dispatch_main_async_safe(^{
                if (success) {
                    path = [AWEDraftUtils relativePathFrom:path taskID:taskId];
                    ACCBLOCK_INVOKE(completion, path, success, nil);
                } else {
                    AWELogToolError(AWELogToolTagSecurity, @"[save] 保存抽帧文件失败（saveImage），error:%@， path:@%", writeError, path);

                    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                        NSError *deleteError = nil;
                        [[NSFileManager defaultManager] removeItemAtPath:path error:&deleteError];
                        if (deleteError) {
                            AWELogToolWarn(AWELogToolTagSecurity, @"[save] 删除文件失败（saveImage），error:%@，path:@%", @(deleteError.code), path);
                        }
                    }

                    ACCBLOCK_INVOKE(completion, nil, success, writeError);
                }
            });
        }
    });
}

+ (void)saveImages:(NSArray<UIImage *> *)frames
              type:(ACCSecurityFrameType)type
            taskId:(NSString *)taskId
        compressed:(BOOL)compressed
        completion:(void (^)(NSArray<NSString *> *paths, BOOL success, NSError *error))completion
{
    acc_dispatch_queue_async_safe([self securitySaveQueue], ^{
        NSMutableArray *paths = [NSMutableArray array];
        
        __block NSError *saveError;
        [frames enumerateObjectsUsingBlock:^(UIImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSString *path = [self p_framePathWithTaskId:taskId compressed:compressed type:type];
                
                UIImage *image;
                NSData *imageData;
                if (compressed) {
                    if (type == ACCSecurityFrameTypeAIRecommond) {
                        image = [self tryCompressImage:obj ifImageSizeLargeTargetSize:[ACCSecurityFramesUtils framesResolutionWithType:type]];
                    } else {
                        image = [UIImage acc_tryCompressImage:obj ifImageSizeLargeTargetSize:[ACCSecurityFramesUtils framesResolutionWithType:type]];
                    }
                    imageData = UIImageJPEGRepresentation(image, [ACCSecurityFramesUtils framesCompressionRatio]);
                } else {
                    image = obj;
                    imageData = UIImageJPEGRepresentation(image, 1.0);
                }

                BOOL success = [imageData acc_writeToFile:path options:NSDataWritingAtomic error:&saveError];
                if (success) {
                    path = [AWEDraftUtils relativePathFrom:path taskID:taskId];
                    [paths acc_addObject:path];
                } else {
                    AWELogToolError(AWELogToolTagSecurity, @"[save] 保存多抽帧文件失败（saveImages），error:%@，path:@%", saveError, path);

                    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                        NSError *deleteError = nil;
                        [[NSFileManager defaultManager] removeItemAtPath:path error:&deleteError];
                        if (deleteError) {
                            AWELogToolWarn(AWELogToolTagSecurity, @"[save] 删除文件失败（saveImages），error:%@，path:@%", @(deleteError.code), path);
                        }
                    }
                }
            }
        }];
        
        acc_dispatch_main_async_safe(^{
            if (paths.count == frames.count && !saveError) {
                ACCBLOCK_INVOKE(completion, paths.copy, YES, nil);
            } else {
                ACCBLOCK_INVOKE(completion, paths.copy, NO, saveError);
            }
        });
    });
}

+ (void)moveImageAtPaths:(NSArray<NSString *> *)fromPaths
                    type:(ACCSecurityFrameType)type
              fromTaskId:(NSString *)fromTaskId
                toTaskId:(NSString *)toTaskId
              completion:(void (^)(NSArray<NSString *> *paths, BOOL success, NSError *error))completion
{
    acc_dispatch_queue_async_safe([self securitySaveQueue], ^{
        NSMutableArray *resultPaths = [[NSMutableArray alloc] init];
        
        NSError *moveError;
        for (NSString *fromPath in fromPaths) {
            NSString *absolutePath = [AWEDraftUtils absolutePathFrom:fromPath taskID:fromTaskId];
            if ([fromTaskId isEqualToString:toTaskId]) {
                [resultPaths acc_addObject:fromPath];
                continue;
            }
            NSString *path = [self p_framePathWithTaskId:toTaskId type:type];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:absolutePath]) {
                [[NSFileManager defaultManager] moveItemAtPath:absolutePath toPath:path error:&moveError];
                if (!moveError) {
                    path = [AWEDraftUtils relativePathFrom:path taskID:toTaskId];
                    [resultPaths acc_addObject:path];
                } else {
                    AWELogToolError(AWELogToolTagSecurity, @"[save] 移动抽帧文件失败，error:%@，path:@%", moveError, path);
                }
            }
        }
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completion, resultPaths.copy, resultPaths.count == fromPaths.count, nil);
        });
    });
}

+ (void)compressImages:(NSArray<NSString *> *)framePaths
                  type:(ACCSecurityFrameType)type
                taskId:(NSString *)taskId
            completion:(void (^)(NSArray<NSString *> *paths, BOOL success, NSError *error))completion
{
    acc_dispatch_queue_async_safe([self securitySaveQueue], ^{
        NSMutableArray *paths = [NSMutableArray array];
        
        __block NSError *saveError;
        [framePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSString *path = [self p_framePathWithTaskId:taskId type:type];
                NSString *imageFullPath = [AWEDraftUtils absolutePathFrom:obj taskID:taskId];
                
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:imageFullPath] scale:[ACCSecurityFramesUtils framesCompressionRatio]];
                image = [UIImage acc_tryCompressImage:image ifImageSizeLargeTargetSize:[ACCSecurityFramesUtils framesResolution]];
                NSData *imageData = UIImageJPEGRepresentation(image, [ACCSecurityFramesUtils framesCompressionRatio]);
                image = nil;
    
                BOOL success = [imageData acc_writeToFile:path options:NSDataWritingAtomic error:&saveError];
                
                if (success) {
                    path = [AWEDraftUtils relativePathFrom:path taskID:taskId];
                    [paths acc_addObject:path];
                } else {
                    AWELogToolError(AWELogToolTagSecurity, @"[save] 压缩后保存抽帧文件失败，image data size: %.fKB，error:%@， path:@%", imageData.length/1024, saveError, path);

                    NSError *deleteError;
                    [[NSFileManager defaultManager] removeItemAtPath:path error:&deleteError];
                }
            }
        }];
        
        acc_dispatch_main_async_safe(^{
            if (paths.count == framePaths.count && !saveError) {
                ACCBLOCK_INVOKE(completion, paths.copy, YES, nil);
            } else {
                ACCBLOCK_INVOKE(completion, paths.copy, NO, saveError);
            }
        });
    });
}

+ (UIImage *)standardCompressImage:(UIImage *)image
{
    UIImage *compressImage = [UIImage acc_tryCompressImage:image ifImageSizeLargeTargetSize:[ACCSecurityFramesUtils framesResolution]];
    NSData *imageData = UIImageJPEGRepresentation(compressImage, [ACCSecurityFramesUtils framesCompressionRatio]);
    
    return [UIImage imageWithData:imageData];
}

#pragma mark - Utils

+ (UIImage *)tryCompressImage:(UIImage *)sourceImage ifImageSizeLargeTargetSize:(CGSize)targetSize
{
    if (sourceImage == nil || targetSize.height == 0 || targetSize.width == 0) {
        return sourceImage;
    }
    
    if (sourceImage.size.width < targetSize.width && sourceImage.size.height < targetSize.height) {
        return sourceImage;
    }
    // 定最小边转换
    CGFloat minimumLength = targetSize.width;
    if (sourceImage.size.width > sourceImage.size.height && sourceImage.size.height > 0) {
        CGSize size = CGSizeZero;
        size.height = minimumLength;
        size.width = (sourceImage.size.width * size.height) / sourceImage.size.height;
        return [UIImage acc_compressImage:sourceImage withTargetSize:size];
    } else if (sourceImage.size.width > 0) {
        CGSize size = CGSizeZero;
        size.width = minimumLength;
        size.height = (sourceImage.size.height * size.width) / sourceImage.size.width;
        return [UIImage acc_compressImage:sourceImage withTargetSize:size];
    } else {
        return sourceImage;
    }
}

+ (NSString *)p_framePathWithTaskId:(NSString *)taskId type:(ACCSecurityFrameType)type
{
    return [ACCSecurityFramesSaver p_framePathWithTaskId:taskId compressed:YES type:type];
}

+ (NSString *)p_framePathWithTaskId:(NSString *)taskId compressed:(BOOL)compressed type:(ACCSecurityFrameType)type
{
    NSAssert(!ACC_isEmptyString(taskId), @"[frame security] taskId is nil");
    
    if (ACC_isEmptyString(taskId)) {
        return nil;
    }
    
    NSString *draftFolder = [AWEDraftUtils generateDraftFolderFromTaskId:taskId];
    NSString *typeName = [self p_folderNameWithType:type];
    NSString *frameFolder = [draftFolder stringByAppendingPathComponent:typeName];
    
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:frameFolder isDirectory:&isDirectory]) {
        NSError *createDirectoryError;
        [[NSFileManager defaultManager] createDirectoryAtPath:frameFolder
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&createDirectoryError];
        if (createDirectoryError) {
            AWELogToolError(AWELogToolTagSecurity, @"[save] 创建frameFolder失败，frameFolder: %@，error: %@", frameFolder, @(createDirectoryError.code));
            frameFolder = draftFolder;
        }
    }
    
    NSString *name = [NSString stringWithFormat:@"%@_%@.jpeg", typeName, @([self p_filesCountInFolder:frameFolder])];
    if (!compressed && ACCSecurityFrameTypeRecord == type) {
        name = [NSString stringWithFormat:@"%@_%@_hq.jpeg", typeName, @([self p_filesCountInFolder:frameFolder])];
    }
    NSString *framePath = [frameFolder stringByAppendingPathComponent:name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:framePath]) {
        name = [NSString stringWithFormat:@"%@_%@.jpeg", typeName, [[NSUUID UUID] UUIDString]];
        if (!compressed && ACCSecurityFrameTypeRecord == type) {
            name = [NSString stringWithFormat:@"%@_%@_hq.jpeg", typeName, [[NSUUID UUID] UUIDString]];
        }
        framePath = [frameFolder stringByAppendingPathComponent:name];
    }
    
    NSAssert(![[NSFileManager defaultManager] fileExistsAtPath:framePath], @"[frame security] invalid frame path = %@", framePath);
    
    return framePath;
}

+ (NSString *)p_folderNameWithType:(ACCSecurityFrameType)type
{
    NSString *name = @"frame_upload";
    
    switch (type) {
        case ACCSecurityFrameTypeUpload:
            name = @"frame_upload";
            break;
            
        case ACCSecurityFrameTypeRecord:
            name = @"frame_record";
            break;
            
        case ACCSecurityFrameTypeTemplate:
            name = @"frame_template";
            break;
            
        case ACCSecurityFrameTypeProps:
            name = @"frame_props";
            break;
            
        case ACCSecurityFrameTypeCustomSticker:
            name = @"frame_custom_sticker";
            break;
            
        case ACCSecurityFrameTypeImageAlbum:
            name = @"frame_image_album";
            break;
            
        case ACCSecurityFrameTypeAIRecommond:
            name = @"frame_ai_recommond";
            break;
            
        default:
            break;
    }
    
    return name;
}

+ (NSUInteger)p_filesCountInFolder:(NSString *)folder
{
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL dir = NO;
    BOOL exist = [manager fileExistsAtPath:folder isDirectory:&dir];
    
    if (!exist) {
        return 0;
    }
    
    if (dir) {
        NSError *error;
        NSArray *contentList = [manager contentsOfDirectoryAtPath:folder error:&error];
        
        return contentList.count;
    }
    
    return 0;
}

@end
