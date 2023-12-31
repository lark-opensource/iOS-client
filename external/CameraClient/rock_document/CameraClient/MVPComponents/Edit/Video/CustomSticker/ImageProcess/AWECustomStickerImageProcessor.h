//
//  AWECustomStickerImageProcessor.h
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/19.
//

#import <Foundation/Foundation.h>

@class AWECustomPhotoStickerEditConfig,AWECustomPhotoStickerClipedInfo,YYImage,AWECustomStickerLimitConfig, BDImage;

@interface AWECustomStickerImageProcessor : NSObject

+ (BOOL)supportCustomStickerForDataUTI:(NSString *)uti isImageAlbumEdit:(BOOL)isImageAlbumEdit;

+ (void)compressInputStickerOriginData:(NSData *)originData isGIF:(BOOL)isGIF limitConfig:(AWECustomStickerLimitConfig *)limitConfig completionBlock:(void(^)(BOOL, YYImage *, UIImage *))completionBlock;

+ (id)requestProcessedStickerImage:(UIImage *)inputImage completion:(void(^)(BOOL, AWECustomPhotoStickerClipedInfo *, UIImage *, NSError *))completionBlock;

+ (void)saveAndSampleStickerImage:(UIImage *)outputImage usePNG:(BOOL)usePNG filePrefix:(NSString *)folderPath completionBlock:(void(^)(BOOL, NSString *, NSArray *))completionBlock;

+ (NSArray<NSString *> *)regenerateTheCustomImageForPath:(NSString *)imagePath;

@end
