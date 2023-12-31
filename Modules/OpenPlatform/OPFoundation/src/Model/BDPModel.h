//
//  BDPModel.h
//  Timor
//
//  Created by liubo on 2018/11/15.
//

#import <Foundation/Foundation.h>
#import "BDPAppMetaBriefProtocol.h"
#import "BDPAppDefine.h"
#import "BDPUniqueID.h"

NS_ASSUME_NONNULL_BEGIN


//@class GadgetMeta;
@protocol AppMetaPackageProtocol;

#pragma mark - BDPModel
//  小程序老版本Meta数据结构，新的是GadgetMeta
/**
 友情提示。meta增加属性时。需要对应处理下NSCopying协议的实现。若该信息需要存入数据库则NSCoding协议也要对应实现下。
 友情提示：meta增加属性时，需要去GadgetMetaProvider和GadgetMeta自身属性及其toJson里添加对应逻辑。
 友情提示：针对H5小程序，后端返回的type字段仍然是小程序的标识，需要维持当前运行时外部传入的应用类型。
 */
@interface BDPModel : NSObject<NSCoding, NSCopying, BDPAppMetaBriefProtocol>

/** 唯一标识, appid+versionType */
@property (nonatomic, strong) BDPUniqueID *uniqueID;

@property (nonatomic, copy) NSString *name;

/// [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
/// 大组件列表
@property (nonatomic, strong, nullable) NSArray<NSDictionary<NSString *, NSString *> *> *components;

/// ttpkg包名，取下载地址最后的path
@property (nonatomic, copy, readonly) NSString *pkgName;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, assign) BDPAppStatus state;
@property (nonatomic, assign) BDPAppVersionStatus versionState;
@property (nonatomic, copy) NSArray<NSString *> *authList; //ttcode
@property (nonatomic, copy) NSArray<NSString *> *blackList; //ttblackcode
@property (nonatomic, copy) NSArray<NSString *> *gadgetSafeUrls; //webview安全域名范围
@property (nonatomic, assign) int64_t versionUpdateTime;
@property (nonatomic, assign) BDPAppShareLevel shareLevel;

@property (nonatomic, copy, nullable) NSString *version; //current_version || version

@property (nonatomic, copy, readonly, nullable) NSString *appVersion; //当前小程序的应用版本【仅关于页展示使用】
/** 小程序编译版本 **/
@property (nonatomic, copy) NSString *compileVersion;
/** 版本更新时间戳 */
@property (nonatomic, assign) int64_t version_code;
/// 包下载地址数组
@property (nonatomic, copy, readonly) NSArray<NSURL *> *urls;

@property (nonatomic, copy) NSString *md5;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *domainsAuthDict;
@property (nonatomic, copy) NSString *minJSsdkVersion;
/// 最低兼容的lark版本
@property (nonatomic, copy) NSString *minLarkVersion;
@property (nonatomic, copy) NSDictionary *extraDict; //is_inner 0=不是头条内部小程序 1=头条内部小程序
@property (nonatomic, copy) NSString *webURL; // H5 版本小程序 URL 标识;
@property (nonatomic, strong, readonly) id<AppMetaPackageProtocol> package;
@property (nonatomic, copy, nullable) NSString *realMachineDebugSocketAddress; // 小程序真机调试连接 IDE 的地址
@property (nonatomic, copy, nullable) NSString *performanceProfileAddress; // 小程序性能调试连接 IDE 的地址


/** 是否已下线 */
@property (nonatomic, readonly) BOOL offline;
/// 应用是否具备对应能力 Message Action
@property (nonatomic, assign) BOOL abilityForMessageAction;
/// 应用是否具备对应能力 +号
@property (nonatomic, assign) BOOL abilityForChatAction;

///迁移到：BDPModel+PackageManager
///// 从GadgetMeta转换为BDPModel
///// @param gadgetMeta 小程序 H5小程序统一的Meta
//- (instancetype)initWithGadgetMeta:(GadgetMeta *)gadgetMeta;

// 下面的几种初始化方法都不再允许调用
+ (instancetype _Nonnull)new NS_UNAVAILABLE;

// 下面的几种初始化方法都不再允许调用
- (instancetype)init NS_UNAVAILABLE;

// 下面的几种初始化方法都不再允许调用
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

// 下面的几种初始化方法都不再允许调用
- (instancetype)initWithDictionary:(NSDictionary *)dic
              uniqueID:(BDPUniqueID *)uniqueID
                           withKey:(NSString *)key
                               vec:(NSString *)iv NS_UNAVAILABLE;

/// 仅用于启动 Loading 界面未获得meta前fake展示图标和名字用途，后续将删除，请勿扩大使用范围
+ (instancetype)fakeModelWithUniqueID:(BDPUniqueID * _Nonnull)uniqueID
                                             name:(NSString * _Nullable)name
                                             icon:(NSString * _Nullable)icon
                                             urls:(NSArray<NSURL *> * _Nullable)urls;

///迁移到：BDPModel+PackageManager
///// 转换为GadgetMeta
//- (GadgetMeta *)toGadgetMeta;

///检查self是否比model版本新
- (BOOL)isNewerThanAppModel:(BDPModel *)model;

///将newestModel的部分属性merge到self
- (void)mergeNewestInfoFromModel:(BDPModel *)newestModel;

/// 获取大组件 names，方便外部使用
- (NSArray *)componentsNames;

#pragma mark - Utility

//仅用于alog
- (NSString *)fullVersionDescription;
/// 字符串 -> NSURL
+ (NSArray<NSURL *> *)urlFromStrings:(NSArray<NSString *> *)urlStrings;

@end

NS_ASSUME_NONNULL_END
