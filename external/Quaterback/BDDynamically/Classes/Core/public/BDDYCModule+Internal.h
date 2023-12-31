//
//  BDDYCModule+Internal.h
//  BDDynamically
//
//  Created by zuopengliu on 7/3/2018.
//

#import <Foundation/Foundation.h>
#import "BDBDModule.h"
#import "BDDYCModuleModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BDDYCModuleOperatingStatus;
@class BDDYCModuleModel;
@interface BDBDModule ()
// Response Module
@property (nonatomic, strong, readwrite) BDDYCModuleModel *moduleModel;

- (BOOL)load;
- (BOOL)loadAndReturnError:(NSError *__autoreleasing *)error;
- (BOOL)loadAndReturnError:(NSError *__autoreleasing  _Nullable *)error
   skipsFileNameValidation:(BOOL)skipFileNameValidation;
- (BOOL)loadLazyLoadDylibAndReturnError:(NSError *__autoreleasing *)error;
- (void)unload;
- (void)unloadAndRemove;
- (void)remove;

- (nullable id)operatingStatus;

// 转化为上报至服务端的补丁结构
- (NSDictionary *)toReportDicitonary;

- (NSDictionary *)toLogDicitonary;

// 转化为存储至本地的补丁结构
- (NSDictionary *)toPropertyListDictionary;

#pragma mark - creation

+ (instancetype)moduleWithBundle:(id)bundleName;
+ (instancetype)moduleWithFiles:(NSArray *)files;

/**
 创建补丁Module
 */
- (instancetype)initWithPropertyDictionary:(NSDictionary *)dict;

- (void)initModuleModel;
@end


#if BDAweme
__attribute__((objc_runtime_name("AWECFIndenture")))
#elif BDNews
__attribute__((objc_runtime_name("TTDBush")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDPanda")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDShepherdPurse ")))
#endif
@interface BDDYCModuleOperatingStatus : NSObject
@property (nonatomic, strong) NSError *loadingError;
@property (nonatomic,   copy) NSArray *loadedClassRecords;
@property (nonatomic,   copy) NSString *sourceFilePath;
@property (nonatomic,   copy) NSString *type; // patch or plugin
@property (nonatomic, strong) NSBundle *bundle;
@end

NS_ASSUME_NONNULL_END

