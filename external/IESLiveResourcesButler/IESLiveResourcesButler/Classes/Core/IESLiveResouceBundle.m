//
//  IESLiveResouceBundle.m
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceBundle.h"
#import "IESLiveResouceManager.h"

NSString * const kIESLiveResourceBundleDynamicKey = @"DynamicParent";

@interface IESLiveResouceBundle ()

@property (nonatomic, strong) IESLiveResouceBundle *parent;
@property (nonatomic, copy) NSString *bundleName;
@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) NSBundle *mainBundle;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, assign)BOOL isImageFromAssets;
@property (nonatomic, copy) NSDictionary<NSString *,IESLiveResouceManager *> *assetManagers;

@end

@implementation IESLiveResouceBundle

- (instancetype)initWithBundle:(NSBundle *)bundle {
    self = [super init];
    if (self) {
        self.bundle = bundle;
        self.bundleName = [bundle.bundlePath lastPathComponent];
        self.category = (NSString *)self.infoDic(@"category");
        self.isImageFromAssets = [(NSNumber *)self.infoDic(@"imageInAssets") boolValue];
        NSString *parentName = (NSString *)self.infoDic(@"parent");
        if (parentName) {
            self.parent = [[self class] assetBundleWithBundleName:parentName];
        }
        NSFileManager *fileManager = [NSFileManager new];
        NSMutableDictionary<NSString *,IESLiveResouceManager *> *managers = [NSMutableDictionary dictionary];
        NSArray *dirs = [fileManager contentsOfDirectoryAtPath:self.bundle.bundlePath error:nil];
        for (NSString *dir in dirs) {
            BOOL isDir = YES;
            if ([fileManager fileExistsAtPath:[bundle.bundlePath stringByAppendingPathComponent:dir] isDirectory:&isDir] && isDir) {
                IESLiveResouceManager *manager = [IESLiveResouceManager instanceWithAssetBundle:self forType:dir];
                if (manager) {
                    [managers setObject:manager forKey:dir];
                }
            }
        }
        if (self.isImageFromAssets && !self.assetManagers[@"image"]) {
            IESLiveResouceManager *manager = [IESLiveResouceManager instanceWithAssetBundle:self forType:@"image"];
            if (manager) {
                [managers setObject:manager forKey:@"image"];
            }
        }
        // 增加config处理能力
        IESLiveResouceManager *manager = [IESLiveResouceManager instanceWithAssetBundle:self forType:@"config"];
        if (manager) {
            [managers setObject:manager forKey:@"config"];
        }

        self.assetManagers = managers;
    }
    return self;
}

- (instancetype)initWithBundleName:(NSString *)bundleName {
    // 处理 动态bundle
    if ([bundleName containsString:kIESLiveResourceBundleDynamicKey]) {
        // 优先获取配置的
        if (self.infoDic(kIESLiveResourceBundleDynamicKey)) {
            bundleName = (NSString *)self.infoDic(kIESLiveResourceBundleDynamicKey);
        } else {
            bundleName = [IESLiveResouceBundle assetBundleNameWithDynamicKey:bundleName];
        }
    }
    if ([bundleName rangeOfString:@"/"].location != NSNotFound) {
        NSString *className = [[bundleName stringByDeletingLastPathComponent] lastPathComponent];
        if (NSClassFromString(className)) {
            NSBundle *classBundle = [NSBundle bundleForClass:NSClassFromString(className)];
            NSString *bundlePath = [classBundle pathForResource:[bundleName lastPathComponent] ofType:nil];
            self = [self initWithBundlePath:bundlePath];
            self.mainBundle = classBundle;
            return self;
        } else if ([className hasSuffix:@".bundle"]) {
            NSURL *bundlePathURL = [[NSBundle mainBundle] URLForResource:[className stringByDeletingPathExtension] withExtension:@"bundle"];
            self.mainBundle = [NSBundle bundleWithURL:bundlePathURL];
            NSString *bundlePath = [self.mainBundle pathForResource:[bundleName lastPathComponent] ofType:nil];
            self = [self initWithBundlePath:bundlePath];
            return self;
        }
    }
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:[bundleName lastPathComponent] ofType:nil];
    self = [self initWithBundlePath:bundlePath];
    return self;
}

- (instancetype)initWithBundlePath:(NSString *)bundlePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        self = [self initWithBundle:bundle];
        return self;
    } else {
        return nil;
    }
}

+ (instancetype)assetBundleWithBundleName:(NSString *)bundleName {
    static NSMapTable<NSString *, IESLiveResouceBundle *> *bundles = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundles = [NSMapTable strongToWeakObjectsMapTable];
    });
    IESLiveResouceBundle *bundle = [bundles objectForKey:bundleName];
    if (!bundle) {
        bundle = [[self alloc] initWithBundleName:bundleName];
        if (bundle) {
            [bundles setObject:bundle forKey:bundleName];
        }
    }
    return bundle;
}

- (id)objectForKey:(NSString *)key type:(NSString *)type {
    id value = [self.assetManagers[type] objectForKey:key];
    if (!value && self.parent) {
        value = [self.parent objectForKey:key type:type];
    }
    return value;
}

static NSDictionary *plistDic = nil;
- (id (^)(NSString *key))infoDic {
    return ^(NSString *key) {
        NSString *plistFilePath = [self.bundle.bundlePath stringByAppendingPathComponent:@"Config.plist"];
        plistDic = [[NSDictionary alloc] initWithContentsOfFile:plistFilePath];
        return plistDic[key];
    };
}

- (BOOL)isImageFromAssets{
    return _isImageFromAssets;
}

@end

@implementation IESLiveResouceBundle (Category)

static NSMutableDictionary<NSString *, NSString *> *bundleCategoryMap = nil;
static NSMutableDictionary<NSString *, NSString *> *bundleDynamicMap = nil;

+ (void)useBundle:(NSString *)bundleName forCategory:(NSString *)category {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundleCategoryMap = [NSMutableDictionary dictionary];
    });
    if (bundleName && category) {
        [bundleCategoryMap setObject:bundleName forKey:category];
    }
}

+ (NSString *)assetBundleNameWithCategory:(NSString *)category {
    if (bundleCategoryMap && category) {
        NSString *bundleName = bundleCategoryMap[category];
        if (bundleName) {
            return bundleName;
        }
    }
    
    return nil;
}

+(void)useBundleName:(NSString *)bundleName forDynamicKey:(NSString *)dynamicKey {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundleDynamicMap = [NSMutableDictionary dictionary];
    });
    if (bundleName && dynamicKey) {
        bundleDynamicMap[dynamicKey] = bundleName;
    } else if (dynamicKey){
        [bundleDynamicMap removeObjectForKey:dynamicKey];
    }
}

+ (NSString *)assetBundleNameWithDynamicKey:(NSString *)dynamicKey {
    if (bundleDynamicMap && dynamicKey) {
        NSString *bundleName = bundleDynamicMap[dynamicKey];
        if (bundleName) {
            return bundleName;
        }
    }
    return nil;
}

+ (IESLiveResouceBundle *)assetBundleWithCategory:(NSString *)category {
    NSString *bundleName = [self assetBundleNameWithCategory:category];
    if (bundleName) {
        return [self assetBundleWithBundleName:bundleName];
    }
    return nil;
}

@end
