//
//  IESLiveResouceManager.m
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceManager.h"
#import "IESLiveResouceBundle.h"

@interface IESLiveResouceManager ()

@property (nonatomic, weak) IESLiveResouceBundle *assetBundle;
@property (nonatomic, copy) NSString *type;

@end

@implementation IESLiveResouceManager

- (instancetype)initWithAssetBundle:(IESLiveResouceBundle *)assetBundle type:(NSString *)type {
    self = [super init];
    if (self) {
        self.assetBundle = assetBundle;
        self.type = type;
    }
    return self;
}

- (id)objectForKey:(NSString *)key {
    return nil;
}

@end

@implementation IESLiveResouceManager (Type)

static NSMutableDictionary *allAssetManagersDictionary = nil;

+ (instancetype)instanceWithAssetBundle:(IESLiveResouceBundle *)assetBundle forType:(NSString *)type {
    Class managerClass = [[self assetManagerClassesForType:type] lastObject];
    if (managerClass) {
        IESLiveResouceManager *manager = [[managerClass alloc] initWithAssetBundle:assetBundle type:type];
        return manager;
    }
    return nil;
}

+ (void)registerAssetManagerClass:(Class)class forType:(NSString *)type {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allAssetManagersDictionary = [NSMutableDictionary dictionary];
    });
    NSMutableArray *managers = allAssetManagersDictionary[type];
    if (!managers) {
        managers = [NSMutableArray array];
        allAssetManagersDictionary[type] = managers;
    }
    [managers addObject:class];
}

+ (NSArray<Class> *)assetManagerClassesForType:(NSString *)type {
    if (allAssetManagersDictionary) {
        return [allAssetManagersDictionary[type] copy];
    }
    return nil;
}

@end
