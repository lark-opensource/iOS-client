//
//  BDDYCModuleModel.h
//  BDDynamically
//
//  Created by zuopengliu on 7/3/2018.
//

#import <Foundation/Foundation.h>
#import "BDQuaterbackConfigProtocol.h"


/**
 [接口Response中单个补丁的信息描述]
 "patch_id":        "xxx",          // 补丁ID          int
 "patch_name":      "xxx",          // 补丁包名         string
 "versioncode":     5,              // 补丁版本号        string
 "appVersion":      "xxx",          // 下发APP的主版本号  string
 "appBuildVersion": "xxx",          // 下发APP的编译版本号 string
 "url":             "xxx",          // 下载url           string
 "md5":             "xxx",          // 下载包md5          string
 "backup_urls": [
    "xxx",
    "xxx",
 ]
 "offline":         false,          // patch开关          int
 "wifionly":        true,           // 是否只在wifi下载     int
 */
@class BDDYCModuleModelDownloadingStatus;

#if BDAweme
__attribute__((objc_runtime_name("AWECFExtricable")))
#elif BDNews
__attribute__((objc_runtime_name("TTDTree")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDBearLeft")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDKale")))
#endif
@interface BDDYCModuleModel : NSObject<BDQuaterbackConfigProtocol>

// 补丁id
@property (nonatomic, copy) NSString *moduleId;

// module name (patch or plugin)
@property (nonatomic, copy) NSString *name;

// module (patch or plugin) version code
@property (nonatomic, copy) NSString *version;

// app main version code
@property (nonatomic, copy) NSString *appVersion;

// app build version code
@property (nonatomic, copy) NSString *appBuildVersion;

// 状态
@property (nonatomic, assign) NSInteger status;

// 是否仅仅wifi环境下进行下载
@property (nonatomic, assign) BOOL wifionly;

// 是否下线补丁，默认NO
@property (nonatomic, assign) BOOL offline;

// module 文件md5
@property (nonatomic, copy) NSString *md5;

// module 文件下载地址
@property (nonatomic, copy) NSString *url;

// module 文件下载备份地址地址
@property (nonatomic, copy) NSArray<NSString *> *backupUrls;

// operation-type: 没用，忘了啥意思
@property (nonatomic, assign) NSInteger operationType;

// 对称加密信息
@property (nonatomic, assign, getter=isEncrypted) BOOL encrypted;
@property (nonatomic, copy) NSString *privateKey;

//是否异步加载patch
@property (nonatomic, assign, getter=isAsync) BOOL async;

@property (nonatomic, copy) NSArray *channelList;
@property (nonatomic, copy) NSArray *appVersionList;
@property (nonatomic, copy) NSDictionary *osVersionRange;
@property (nonatomic, copy) NSString *loadEnable;

@property (nonatomic, assign) int hookType;

#pragma mark -

- (NSString *)uniquekey;

+ (instancetype)modelWithDictionary:(NSDictionary *)dict;

// 转化为本地存储的结构
- (NSDictionary *)toPropertyListDictionary;

// 转化为上传至服务端的结构 {"name": ***, "": ***}
- (NSDictionary *)toReportDicitonary;

- (NSDictionary *)toLogDicitonary;

/**
 判断当前module与另外的module相比较是否需要更新
 
 @param otherModel 被比较的module信息
 @return 需要更新返回YES，否则返回NO
 */
- (BOOL)needsUpdateCompareToObject:(BDDYCModuleModel *)otherModel;

@end

@interface BDDYCModuleModel (ModelsCreation)

#pragma mark - instance

/**
 通过网络响应来生成model数据
 @Wiki: https://wiki.bytedance.net/pages/viewpage.action?pageId=63231477

 Format:
 {
 "patch": [ {
 
 }, {
 
 }
 ],
 }
 */
+ (NSArray *)modelsWithDictionary:(NSDictionary *)dict;

+ (NSArray *)modelsWithArray:(NSArray *)array;

@end

@interface BDDYCModuleModel (DownloadingStatus)

- (NSString *)nextDownloadUrl;

- (BOOL)containsAvailableUrl;

- (void)startDownloadUrl:(NSString *)url;

- (void)recordError:(NSError *)error forDownloadUrl:(NSString *)url;

- (NSError *)lastDownloadError;

@end
