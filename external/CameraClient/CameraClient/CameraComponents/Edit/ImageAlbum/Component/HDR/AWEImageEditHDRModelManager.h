//
//  AWEImageEditHDRModelManager.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEImageEditHDRModelManager : NSObject

+ (void)downloaImageLensHDRResourceIfNeeded;

+ (BOOL)enableImageLensHDR;

+ (NSString *)lensHDRFilePath;

+ (NSArray <NSString *> *)lensHDRModelNames;

+ (BOOL)didLensHDRResourcesDownloaded;

@end

NS_ASSUME_NONNULL_END
