//
//  TSPKCallStackCacheInfo.m
//  BDAlogProtocol
//
//  Created by bytedance on 2022/7/21.
//

#import "TSPKCallStackCacheInfo.h"
#import "TSPKCallStackMacro.h"
#import "TSPKCallStackRuleInfo.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "TSPrivacyKitConstants.h"

@implementation TSPKCallStackCacheInfo

+ (instancetype)sharedInstance {
    static TSPKCallStackCacheInfo *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[TSPKCallStackCacheInfo alloc] init];
    });
    return _instance;
}

- (NSDictionary *)loadWithVersion:(NSString *)ver {
    return [NSDictionary dictionaryWithContentsOfFile:[self cachePath:ver]];
}

- (void)save:(NSDictionary *)info forVersion:(NSString *)ver {
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionary];
    [info enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, TPSKCallStackDataTypeInfo *_Nonnull ruleInfo, BOOL * _Nonnull stop) {
        NSMutableDictionary *dataTypeInfo = [NSMutableDictionary dictionary];

        [ruleInfo.rules enumerateObjectsUsingBlock:^(TSPKCallStackRuleInfo * _Nonnull methodInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([methodInfo isCompleted]) {
                NSString *k = [methodInfo uniqueKey];
                NSMutableDictionary *v = [NSMutableDictionary dictionary];
                [v btd_setObject:methodInfo.binaryName forKey:TSPKMethodBinaryKey]; // only need store binary name and end address
                [v btd_setObject:@(methodInfo.end) forKey:TSPKMethodEndKey];
                [dataTypeInfo btd_setObject:v forKey:k];
            }
        }];
        mutableDic[key] = dataTypeInfo.copy;
    }];

    [mutableDic writeToFile:[self cachePath:ver] atomically:YES];
}

- (NSString *)cachePath:(NSString *)ver {
    static NSString *filePath = nil;
    if (filePath == nil) {
        NSString *folderPath = [@"tspk" btd_prependingDocumentsPath];
        NSString *fileName = [NSString stringWithFormat:@"ctrl_%@.dat", ver];
        filePath = [folderPath stringByAppendingPathComponent:fileName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:filePath]) {
            [fileManager removeItemAtPath:folderPath error:nil];
        }
        if (![fileManager fileExistsAtPath:folderPath]) {
            [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return filePath;
}

@end
