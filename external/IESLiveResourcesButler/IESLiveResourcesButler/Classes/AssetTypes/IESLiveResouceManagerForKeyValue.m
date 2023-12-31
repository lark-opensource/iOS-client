//
//  IESLiveResouceForKeyValue.m
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceManagerForKeyValue.h"

@interface IESLiveResouceManagerForKeyValue ()

@property (nonatomic, strong) NSArray *plists;

@end

@implementation IESLiveResouceManagerForKeyValue

+ (void)load {
    [IESLiveResouceManager registerAssetManagerClass:[self class] forType:@"keyvalue"];
    [IESLiveResouceManager registerAssetManagerClass:[self class] forType:@"config"];
}

- (NSArray *)plists {
    if (!_plists) {
        //plist文件允许有多个
        NSArray *plistFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self.assetBundle.bundle.bundlePath stringByAppendingPathComponent:self.type] error:nil];
        NSMutableArray *plistDics = [NSMutableArray array];
        for (NSString *plistFile in plistFiles) {
            NSString *plistFilePath = [[self.assetBundle.bundle.bundlePath stringByAppendingPathComponent:self.type] stringByAppendingPathComponent:plistFile];
            NSDictionary *plistDic = [[NSDictionary alloc] initWithContentsOfFile:plistFilePath];
            if (plistDic) {
                [plistDics addObject:plistDic];
            }
        }
        _plists = [plistDics copy];
    }
    return _plists;
}

- (id)objectForKey:(NSString *)key {
    // 支持对config的读取
    if ([self.type isEqualToString:@"config"]) {
        NSString *plistFilePath = [self.assetBundle.bundle.bundlePath stringByAppendingPathComponent:@"Config.plist"];
        NSDictionary *plistDic = [[NSDictionary alloc] initWithContentsOfFile:plistFilePath];
        id value = [plistDic objectForKey:key];
        if (value) {
            return value;
        }
        return nil;
    }
    for (NSDictionary *plistDic in self.plists) {
        id value = [plistDic objectForKey:key];
        if (value) {
            return value;
        }
    }
    return nil;
}

@end
