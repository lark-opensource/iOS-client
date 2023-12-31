//
//  IESLiveResouceManagerForImage.m
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceManagerForImage.h"

@interface IESLiveResouceManagerForImage ()

@property (nonatomic, copy) NSString *imageNamedPrefix;
@property (nonatomic, copy) NSDictionary *fileMap;

@end

@implementation IESLiveResouceManagerForImage

+ (void)load {
    [IESLiveResouceManager registerAssetManagerClass:[self class] forType:@"image"];
}

- (instancetype)initWithAssetBundle:(IESLiveResouceBundle *)assetBundle type:(NSString *)type {
    self = [super initWithAssetBundle:assetBundle type:type];
    if (self) {
        if (!self.assetBundle.isImageFromAssets) {
            self.imageNamedPrefix = [assetBundle.bundleName stringByAppendingPathComponent:type];
            NSMutableDictionary *fileMap = [NSMutableDictionary dictionary];
            NSString *typePath = [assetBundle.bundle.bundlePath stringByAppendingPathComponent:type];
            NSArray *allFiles = [[NSFileManager defaultManager] subpathsAtPath:typePath];
            for (NSString *file in allFiles) {
                if ([file rangeOfString:@"@"].location != NSNotFound) {
                    NSString *fileName = [[[file.lastPathComponent stringByDeletingPathExtension] componentsSeparatedByString:@"@"] firstObject];
                    NSString *filePath = [[file stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
                    if (fileName && filePath) {
                        [fileMap setObject:filePath forKey:fileName];
                    }
                }
            }
            self.fileMap = fileMap;
        }
    }
    return self;
}

- (UIImage *)objectForKey:(NSString *)key {
    UIImage *image = nil;
    if (self.assetBundle.isImageFromAssets) {
        image = [UIImage imageNamed:key inBundle:self.assetBundle.bundle compatibleWithTraitCollection:nil];
        return image;
    } else {
    NSString *filePath = self.fileMap[key];
    if (filePath) {
        NSString *filepath = [self.imageNamedPrefix stringByAppendingPathComponent:filePath];
        image = [UIImage imageNamed:filepath inBundle:self.assetBundle.mainBundle compatibleWithTraitCollection:nil];
        }
        return image;
    }
}

@end
