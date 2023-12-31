//
//  ACCSecurityFramesSaver.h
//  AWEStudioService-Pods-Aweme
//
//  Created by lixingdong on 2021/3/31.
//

#import <Foundation/Foundation.h>
#import "ACCSecurityFramesUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCSecurityFramesSaver : NSObject

/// save image to local, default be compressed.
/// @param frame frame to save
/// @param type frame type
/// @param taskId publishModel.taskId
/// @param completion compltion block
+ (void)saveImage:(UIImage *)frame
             type:(ACCSecurityFrameType)type
           taskId:(NSString *)taskId
       completion:(void (^)(NSString *path, BOOL success, NSError *error))completion;

/// save a group of images to local, default be compressed.
/// @param frames frames to save
/// @param type frame type
/// @param taskId publishModel.taskId
/// @param completion compltion block
+ (void)saveImages:(NSArray<UIImage *> *)frames
              type:(ACCSecurityFrameType)type
            taskId:(NSString *)taskId
        completion:(void (^)(NSArray<NSString *> *paths, BOOL success, NSError *error))completion;

/// save image to local
/// @param frame frame to save
/// @param type frame type
/// @param taskId publishModel.taskId
/// @param compressed compress or not
/// @param completion compltion block
+ (void)saveImage:(UIImage *)frame
             type:(ACCSecurityFrameType)type
           taskId:(NSString *)taskId
       compressed:(BOOL)compressed
       completion:(void (^)(NSString *path, BOOL success, NSError *error))completion;

/// save a group of images to local
/// @param frames frames to save
/// @param type frame type
/// @param taskId publishModel.taskId
/// @param compressed compress or not
/// @param completion compltion block
+ (void)saveImages:(NSArray<UIImage *> *)frames
              type:(ACCSecurityFrameType)type
            taskId:(NSString *)taskId
        compressed:(BOOL)compressed
        completion:(void (^)(NSArray<NSString *> *paths, BOOL success, NSError *error))completion;

+ (void)moveImageAtPaths:(NSArray<NSString *> *)fromPaths
                    type:(ACCSecurityFrameType)type
              fromTaskId:(NSString *)fromTaskId
                toTaskId:(NSString *)toTaskId
              completion:(void (^)(NSArray<NSString *> *paths, BOOL success, NSError *error))completion;

/// compress a group of images to local.
/// @param framePaths frames to be compressed.
/// @param type frame type
/// @param taskId publishModel.taskId
/// @param completion compltion block
+ (void)compressImages:(NSArray<NSString *> *)framePaths
                  type:(ACCSecurityFrameType)type
                taskId:(NSString *)taskId
            completion:(void (^)(NSArray<NSString *> *paths, BOOL success, NSError *error))completion;


/// compress image for security
/// @param image image be impressed.
+ (UIImage *)standardCompressImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
