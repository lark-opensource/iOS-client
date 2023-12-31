//
//  BDDYCModuleManager.h
//  BDDynamically
//
//  Created by zuopengliu on 7/3/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 BDDYCModule缓存
 */
@class BDBDModule;

#if BDAweme
__attribute__((objc_runtime_name("AWECFObject")))
#elif BDNews
__attribute__((objc_runtime_name("TTDFern")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDGiraffe	")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDChineseCabbage")))
#endif
@interface BDDYCModuleManager : NSObject
@property (nonatomic, strong, readonly) NSArray *allModulesToRemove;
@property (nonatomic, strong, readonly) NSArray *allModules;

+ (instancetype)sharedManager;

- (void)addModule:(id)aModule;
- (void)addModules:(NSArray *)modules;
- (void)addFailedModule:(id)aModule;
- (void)addLoadedModule:(id)aModule;

- (BDBDModule *)moduleForName:(NSString *)aModuleName;

- (void)removeModule:(id)aModule;
- (void)removeModuleForName:(NSString *)aModuleName;

/**
 获取所有需要上报的补丁列表
 
 @return 所有补丁信息
 */
- (NSArray *)allToReportModules;

- (NSArray *)allToLogModules;

- (NSArray *)allLoadedQuaterbacks;

- (BDBDModule *)didLoadModuleWithName:(NSString *)name;

+ (void)clearAllLocalQuaterback;
@end



@interface BDDYCModuleManager (FileManager)
// 获取本地所有补丁列表信息
+ (NSArray<BDBDModule *> *)allModules;

// 保存当前所有补丁信息至本地文件
- (void)saveToFile;

// 保存所有补丁信息至本地补丁文件
+ (BOOL)saveToFileWithModules:(NSArray<BDBDModule *> *)allModules;

// 新增补丁信息至本地补丁文件
+ (BOOL)appendToFileWithModules:(NSArray<BDBDModule *> *)allModules;

// 补丁文件目录
+ (NSString *)alphaMainDirectory;

+ (NSString *)moduleDirectoryWithModuleName:(NSString *)moduleName;

//删除某个补丁
+ (BOOL)clearLocalQuaterbackWithModule:(BDBDModule *)module;
@end

NS_ASSUME_NONNULL_END


#define KBDDYCQuaterbackMainDirectory    ([BDDYCModuleManager alphaMainDirectory])

#define kBDDYCGetLocalQuaterbackModules  ([BDDYCModuleManager allModules])

#define kBDDYCQuaterbackModuleDirectory(x) ([BDDYCModuleManager moduleDirectoryWithModuleName:x])

