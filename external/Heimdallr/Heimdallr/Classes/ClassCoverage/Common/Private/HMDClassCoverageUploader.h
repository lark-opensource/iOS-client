//
//  HMDClassCoverageUploader.h
//  Pods
//
//  Created by kilroy on 2020/6/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const kHMDClassCoverageFileName = @"class_init_info.dat";

@interface HMDClassCoverageUploader : NSObject

- (void) uploadAfterAppLaunched;

+ (void)cleanFilesInPath:(NSString* _Nonnull) path;

+ (void)cleanClassCoverageFiles;

+ (NSString *)classCoveragePath;

@end

NS_ASSUME_NONNULL_END
