//
//  HMDHermasHelper.h
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 2/6/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define SEC_PER_DAY (24 * 60 * 60)
#define BYTE_PER_MB (1024 * 1024)
#define MILLISECONDS 1000

extern NSString * const kHermasPlistSuiteName;
extern NSString * const kModulePerformaceName;
extern NSString * const kModuleExceptionName;
extern NSString * const kModuleUserExceptionName;
extern NSString * const kModuleOpenTraceName;
extern NSString * const kModuleHighPriorityName;

@interface HMDDatabaseOperationRecord : NSObject

@property (nonatomic, copy) NSString *tableName;

@property (nonatomic, strong) NSArray *andConditions;

@property (nonatomic, strong) NSArray *orConditions;

@property (nonatomic, assign) NSInteger limitCount;

@end

@interface HMDHermasHelper : NSObject

+ (NSString *)rootPath;

+ (NSUserDefaults *)customUserDefault;

+ (NSString *)urlStringWithHost:(NSString *)host path:(NSString *)path;

+ (BOOL)recordImmediately;

@end

NS_ASSUME_NONNULL_END
