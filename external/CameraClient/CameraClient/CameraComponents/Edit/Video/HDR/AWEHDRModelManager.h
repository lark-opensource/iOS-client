//
//  AWEHDRModelManager.h
//  Pods
//
//  Created by wang ya on 2019/8/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEHDRModelManager : NSObject

+ (BOOL)enableVideoHDR;

+ (void)downloadAlgorithmModelIfNeeded;

+ (NSString *)lensModelPath;

+ (NSString *)modelNameForScene:(int)scene;

+ (NSString *)modelPathForScene:(int)scene;

+ (NSArray<NSString *> *)lensHDRModelNames;

@end

NS_ASSUME_NONNULL_END
