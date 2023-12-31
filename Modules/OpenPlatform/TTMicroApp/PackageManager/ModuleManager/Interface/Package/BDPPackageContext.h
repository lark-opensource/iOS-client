//
//  BDPPackageContext.h
//  Timor
//
//  Created by houjihu on 2020/5/21.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPModuleEngineType.h>
#import "BDPPackageInfoManagerProtocol.h"
#import <OPFoundation/BDPModel.h>
#import <OPFoundation/BDPTracing.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AppMetaProtocol;
@protocol AppMetaSubPackageProtocol;
typedef NS_ENUM(NSInteger, BDPSubPackageType) {
    BDPSubPkgTypeNormal = 0,//整包
    BDPSubPkgTypeMain,//主包
    BDPSubPkgTypeIndependent,//独立分包
    BDPSubPkgTypeSub//分包
};

/// 包类型
typedef NS_ENUM(NSUInteger, BDPPackageType) {
    /// zip包
    BDPPackageTypeZip,
    /// 流式包
    BDPPackageTypePkg,
    /// 原始数据类型(e.g.增量更新使用的Patch包)
    BDPPackageTypeRaw
};

/// 包管理所需上下文信息
@interface BDPPackageContext : NSObject

/// 应用唯一标志符
@property (nonatomic, strong, readonly) BDPUniqueID *uniqueID;

/// 版本
@property (nonatomic, copy, readonly) NSString *version;

/// 代码包下载地址
@property (nonatomic, strong, readonly) NSArray<NSURL *> *urls;

/// 包存储名称
@property (nonatomic, copy, readonly) NSString *packageName;

/// 包类型
@property (nonatomic, assign, readonly) BDPPackageType packageType;

/// 包校验码
@property (nonatomic, copy, nullable, readonly) NSString *md5;

/// 增量更新的diff包信息
@property (nonatomic, copy, nullable, readonly) NSDictionary *diffPkgInfos;

/// 包下载类型，内部参数，外部可不传
@property (nonatomic, assign) BDPPkgFileReadType readType;

/// 用于标记 PackageContext 的Trace
@property (nonatomic, strong, readonly) BDPTracing *trace;

/// 分包类型，默认是0，整包
@property (nonatomic, readonly, assign) BDPSubPackageType subPackageType;
//分包上下文列表，包含所有的分包信息
@property (nonatomic, readonly, strong) NSArray <BDPPackageContext *> * subPackages;
//分包下载上下文关联的 AppMetaSubPackageProtocol 协议对象，只有当前包类型是 主、分、独立分包时候才会有
@property (nonatomic, readonly, strong) id<AppMetaSubPackageProtocol>  metaSubPackage;

@property (nonatomic, readonly, strong, nullable) id<AppMetaProtocol>  appMeta;
/// 包下载类型，内部参数，外部可不传
@property (nonatomic, readonly, nullable, copy) NSString * startPage;
/// 在load开始前更新启动新页相关信息（分包加载相关，决定是否需要下载某个分包）
-(void)updateStartPage:(nullable NSString *)startPage;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 根据当前应用类型（小程序 或者 H5小程序 或者card）的meta，初始化包管理上下文信息
/// @param appMeta 当前应用类型（小程序 或者 H5小程序 或者card）的meta
/// @param packageType 包类型
/// @param packageName 包存储名称
- (instancetype)initWithAppMeta:(id<AppMetaProtocol>)appMeta
                    packageType:(BDPPackageType)packageType
                    packageName:(nullable NSString *)packageName
                          trace:(BDPTracing *)trace;

/// 根据BDPUniqueID构建包下载上下文
/// @param uniqueID 应用ID
/// @param version 包版本
/// @param urls 包下载路径
/// @param packageName 包名
/// @param packageType 包类型(流式包还是zip包)
/// @param md5 包的MD5值
/// @param trace 埋点使用的trace
- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID
                         version:(NSString *)version
                            urls:(NSArray<NSURL *> *)urls
                     packageName:(NSString *)packageName
                     packageType:(BDPPackageType)packageType
                             md5:(nullable NSString *)md5
                           trace:(BDPTracing *)trace;

/// 打开 pagePath 对应的页面时，必须依赖的包
/// 根据依赖的先后顺序进行排列
/// 1、若打开独立分包页面, 只返回独立分包
/// 2、若打开分包页面，返回主包+分包（优先主包）
/// 3、其他：只返回主包
/// @param pagePath 当前打开页面
-(NSArray <BDPPackageContext *> *)requiredSubPackagesWithPagePath:(NSString *) pagePath;
@end

/// 预安装相关逻辑分类
@interface BDPPackageContext(Prehandle)
/// 预安装场景
@property (nonatomic, copy, nullable) NSString *prehandleSceneName;
/// 预拉的时候使用的策略
@property (nonatomic, assign) NSInteger preUpdatePullType;
@end

NS_ASSUME_NONNULL_END
