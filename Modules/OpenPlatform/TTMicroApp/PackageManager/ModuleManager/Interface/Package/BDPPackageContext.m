//
//  BDPPackageContext.m
//  Timor
//
//  Created by houjihu on 2020/5/21.
//

#import "BDPPackageContext.h"
#import <ECOInfra/NSString+BDPExtension.h>
#import "BDPModel+PackageManager.h"
#import <OPFoundation/BDPModel+H5Gadget.h>
#import <OPFoundation/BDPUniqueID.h>

#import <TTMicroApp/TTMicroApp-Swift.h>

@interface BDPPackageContext ()

/// 应用标识
@property (nonatomic, strong, readwrite) BDPUniqueID *uniqueID;

/// 版本
@property (nonatomic, copy, readwrite) NSString *version;

/// 代码包下载地址
@property (nonatomic, strong, readwrite) NSArray<NSURL *> *urls;

/// 包存储名称
@property (nonatomic, copy, readwrite) NSString *packageName;

/// 包类型
@property (nonatomic, assign, readwrite) BDPPackageType packageType;

/// 包校验码
@property (nonatomic, copy, nullable, readwrite) NSString *md5;

@property (nonatomic, copy, nullable, readwrite) NSDictionary *diffPkgInfos;

/// 用于标记 PackageContext 的Trace
@property (nonatomic, strong, readwrite) BDPTracing *trace;

@property (nonatomic, readwrite, strong, nullable) id<AppMetaProtocol>  appMeta;

@property (nonatomic, readwrite, strong) NSArray <BDPPackageContext *> * subPackages;
@property (nonatomic, readwrite, assign) BDPSubPackageType subPackageType;
@property (nonatomic, readwrite, strong) id<AppMetaSubPackageProtocol>  metaSubPackage;
@property (nonatomic, readwrite, nullable, copy) NSString * startPage;
@end

@implementation BDPPackageContext
- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID
                         version:(NSString *)version
                            urls:(NSArray<NSURL *> *)urls
                     packageName:(NSString *)packageName
                     packageType:(BDPPackageType)packageType
                             md5:(NSString *)md5
                           trace:(BDPTracing *)trace {
    if (self = [super init]) {
        self.uniqueID = uniqueID;
        self.version = version;
        self.urls = urls;
        self.packageName = packageName;
        self.packageType = packageType;
        self.md5 = md5;
        // trace兜底
        if (!trace) {
            trace = BDPTracingManager.sharedInstance.generateTracing;
        }
        self.trace = trace;
    }
    return self;
}

/// 便利化初始方法：根据当前应用类型（小程序 或者 H5小程序 或者card）的model，初始化包管理上下文信息
- (instancetype)initWithAppMeta:(id<AppMetaProtocol>)appMeta
                    packageType:(BDPPackageType)packageType
                    packageName:(NSString *)packageName
                          trace:(BDPTracing *)trace {
    BDPPackageContext * context =  [self
            initWithUniqueID:appMeta.uniqueID
            version:appMeta.version
            urls:appMeta.packageData.urls
            packageName:packageName
            packageType:packageType
            md5:appMeta.packageData.md5
            trace:trace
            ];
    context.appMeta = appMeta;
    context.subPackageType = BDPSubPkgTypeNormal;

    if ([OPSDKFeatureGating packageIncremetalUpdateEnable]) {
        id packageData = (id)appMeta.packageData;
        if ([packageData respondsToSelector:@selector(conformsToProtocol:)] && [packageData conformsToProtocol:@protocol(AppMetaDiffPackageProtocol)]) {
            context.diffPkgInfos = ((id<AppMetaDiffPackageProtocol>)packageData).diffPkgPath;
        }
    }

    //关联分包相关的上下文信息
    if ([(NSObject *)appMeta isKindOfClass:[GadgetMeta class]] && appMeta.packageData.subPackages.count>0 ) {
        NSMutableArray * subPackages= @[].mutableCopy;
        [appMeta.packageData.subPackages enumerateObjectsUsingBlock:^(id<AppMetaSubPackageProtocol>  _Nonnull metaSubPackage,
                                                                      NSUInteger idx, BOOL * _Nonnull stop) {
            BDPPackageContext * subPackageContext = [[BDPPackageContext alloc] initWithUniqueID:appMeta.uniqueID
                                                                                        version:appMeta.version
                                                                                           urls:metaSubPackage.urls
                                                                                    packageName:nil
                                                                                    packageType:packageType
                                                                                            md5:metaSubPackage.md5
                                                                                          trace:trace];
            /**
             根据首次需要打开页面决定包的下载规则，
             1. 如果是打开分包页，下载分包+主包
             2. 如果是打开独立分包页，优先下载独立分包，下载完之后再异步下载主包
             3、其他，先下载主包，之后下载独立分包
             */
            if (metaSubPackage.isMainPackage) {
                subPackageContext.subPackageType = BDPSubPkgTypeMain;
            } else if (metaSubPackage.isIndependent){
                subPackageContext.subPackageType = BDPSubPkgTypeIndependent;
            } else {
                subPackageContext.subPackageType = BDPSubPkgTypeSub;
            }
            subPackageContext.metaSubPackage = metaSubPackage;
            [subPackages addObject:subPackageContext];
        }];
        context.subPackages = subPackages;
    }
    return context;
}

/// 便利化初始方法：根据当前应用类型（小程序 或者 H5小程序）的model，初始化包管理上下文信息
- (instancetype)initWithBDPModel:(BDPModel *)model
                     packageType:(BDPPackageType)packageType
                     packageName:(NSString *)packageName
                           trace:(BDPTracing *)trace {
    return [self
            initWithUniqueID:model.uniqueID
            version:model.version
            urls:model.urls
            packageName:packageName
            packageType:packageType
            md5:model.md5
            trace:trace
            ];
}

/// 为代码包存放目录提供默认实现
- (NSString *)packageName {
    if (!_packageName) {
        _packageName = [self.urls.firstObject.path bdp_fileName];
    }
    return _packageName;
}

-(void)updateStartPage:(nullable NSString *)startPage
{
    self.startPage = startPage;
}

-(NSArray <BDPPackageContext *> *)requiredSubPackagesWithPagePath:(NSString *) pagePath
{
    NSMutableArray<BDPPackageContext *> * requiredPackages = @[].mutableCopy;
    for (BDPPackageContext * subPackage in self.subPackages) {
        if(subPackage.subPackageType == BDPSubPkgTypeMain){
            [requiredPackages addObject:subPackage];
        }else if ([pagePath hasPrefix:subPackage.metaSubPackage.path]) {
            if (subPackage.subPackageType == BDPSubPkgTypeIndependent) {
                //如果要打开独立分包，直接返回
                return @[subPackage];
            } else {
                //找到依赖的分包，添加一下
                [requiredPackages addObject:subPackage];
            }
        }
        //依赖的包不可能超过两个，最多一个主包+一个分包
        if (requiredPackages.count == 2) {
            break;;
        }
    }
    //如果依赖包里主包在后面，需要调整顺序，优先保证下载主包
    if (requiredPackages.count > 1 && requiredPackages.firstObject.subPackageType != BDPSubPkgTypeMain) {
        [requiredPackages exchangeObjectAtIndex:0 withObjectAtIndex:1];
    }
    return requiredPackages;
}

@end

@implementation BDPPackageContext(Prehandle)
#pragma - mark Getter & Setter
- (NSString *)prehandleSceneName {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPrehandleSceneName:(NSString *)prehandleScene {
    objc_setAssociatedObject(self, @selector(prehandleSceneName), prehandleScene, OBJC_ASSOCIATION_COPY);
}

- (NSInteger)preUpdatePullType {
    NSNumber *value = objc_getAssociatedObject(self, _cmd);
    if (!value) {
        return -1;
    }
    return [value integerValue];
}

- (void)setPreUpdatePullType:(NSInteger)preUpdatePullType {
    objc_setAssociatedObject(self, @selector(preUpdatePullType), @(preUpdatePullType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
