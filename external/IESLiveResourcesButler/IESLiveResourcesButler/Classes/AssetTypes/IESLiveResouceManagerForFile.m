//
//  IESLiveResouceManagerForFile.m
//  IESLiveResourcesButler
//
//  Created by lishuangyang on 2019/5/29.
//

#import "IESLiveResouceManagerForFile.h"

@interface IESLiveResouceManagerForFile ()

@property (nonatomic, copy) NSString *bundleFilePrefix;

@property (nonatomic, copy) NSString *type;

@end

@implementation IESLiveResouceManagerForFile

+ (void)load {
    [IESLiveResouceManager registerAssetManagerClass:[self class] forType:@"file"];
    [IESLiveResouceManager registerAssetManagerClass:[self class] forType:@"bundle"];
}

- (instancetype)initWithAssetBundle:(IESLiveResouceBundle *)assetBundle type:(NSString *)type {
    self = [super initWithAssetBundle:assetBundle type:type];
    if (self) {
        self.bundleFilePrefix = [assetBundle.bundleName stringByAppendingPathComponent:type];
        self.type = type;
    }
    return self;
}

- (NSString *)objectForKey:(NSString *)key {
    NSString *pathForResource = key.stringByDeletingPathExtension;
    NSString *type = key.pathExtension;
    NSString *fullPath = [self _recursiveGetPathForResource:pathForResource ofType:type inDirectory:self.type];
    return fullPath.length > 0 ? fullPath : nil;
}

- (NSString *)_recursiveGetPathForResource:(NSString *)name ofType:(NSString *)type inDirectory:(NSString *)subpath {
    if (!name) {
        return nil;
    }
    
    NSString *targetFilePath = [self.assetBundle.bundle pathForResource:name ofType:type inDirectory:subpath];
    if (!targetFilePath) {
        // get recursive path
        NSString *recursivePath = self.assetBundle.bundle.bundlePath;
        if (subpath) {
            recursivePath = [recursivePath stringByAppendingPathComponent:subpath];
        }
        if (name.pathComponents.count > 1) {
            recursivePath = [recursivePath stringByAppendingPathComponent:name.stringByDeletingLastPathComponent];
            name = name.lastPathComponent;
        }
        
        NSDirectoryEnumerator<NSString *> *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:recursivePath];
        for (NSString *path in enumerator) {
            if (![name isEqualToString:path.lastPathComponent.stringByDeletingPathExtension]) {
                // name not match
                continue;
            }
            
            BOOL filePathExtensionMatch = YES;
            if (type) {
                filePathExtensionMatch = [type isEqualToString:path.pathExtension];
            }
            if (!filePathExtensionMatch) {
                // path extension not match
                continue;
            }
            
            NSString *fullPath = [recursivePath stringByAppendingPathComponent:path];
            BOOL isDirectory = NO;
            [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
            if (!isDirectory) {
                targetFilePath = fullPath;
                break;
            }
        }
    }
    return targetFilePath;
}

@end
