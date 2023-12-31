//
//  IESLiveResouceManagerForString.m
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceManagerForString.h"

#define IESLiveResouceEmptyStringValue    @"∅"

@interface IESLiveResouceManagerForString ()

@property (nonatomic, strong) NSArray *tables;
@property (nonatomic, strong) NSCache<NSString*, NSString*> *stringCache;

@end

@implementation IESLiveResouceManagerForString

+ (void)load {
    [IESLiveResouceManager registerAssetManagerClass:[self class] forType:@"string"];
    [IESLiveResouceManager registerAssetManagerClass:[self class] forType:@"pageurl"];
    [IESLiveResouceManager registerAssetManagerClass:[self class] forType:@"color"];
}

- (instancetype)initWithAssetBundle:(IESLiveResouceBundle *)assetBundle type:(NSString *)type {
    self = [super initWithAssetBundle:assetBundle type:type];
    if (self) {
        //string文件允许有多个
        NSArray *tableFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[assetBundle.bundle.bundlePath stringByAppendingPathComponent:type] error:nil];
        NSMutableArray *tableNamesWithoutExt = [NSMutableArray array];
        for (NSString *tableFile in tableFiles) {
            [tableNamesWithoutExt addObject:[type stringByAppendingPathComponent:[tableFile stringByDeletingPathExtension]]];
        }
        self.tables = [tableNamesWithoutExt copy];
        _stringCache = [[NSCache alloc] init];
        _stringCache.countLimit = 256;
    }
    return self;
}

- (NSString *)objectForKey:(NSString *)key {
    for (NSString *table in self.tables) {
        id value = [self.stringCache objectForKey:key];
        if (value) {
            return [value isKindOfClass:[NSNull class]] ? nil : value;
        }
        
        NSString *string = NSLocalizedStringWithDefaultValue(key, table, self.assetBundle.bundle, IESLiveResouceEmptyStringValue, nil);
        if (string && ![string isEqualToString:IESLiveResouceEmptyStringValue]) {
            [self.stringCache setObject:string forKey:key];
            return string;
        }
    }
    
    [self.stringCache setObject:[NSNull null] forKey:key];
    return nil;
}

@end
