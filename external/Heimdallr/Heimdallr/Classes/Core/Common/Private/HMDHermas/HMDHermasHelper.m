//
//  HMDHermasHelper.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 2/6/2022.
//

#import "HMDHermasHelper.h"
#import "HMDGeneralAPISettings.h"
#import "HeimdallrUtilities.h"
#import "HMDFileTool.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "HMDUploadHelper.h"
#import "HMDInjectedInfo.h"
#import "HMDMacro.h"
#if !RANGERSAPM
#import <TTMacroManager/TTMacroManager.h>
#endif
#import "HMDURLHelper.h"
#import "HMDMacroManager.h"
@implementation HMDDatabaseOperationRecord

@end

@implementation HMDHermasHelper

+ (NSString *)rootPath {
    NSString *heimdallrPath  = [HeimdallrUtilities heimdallrRootPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:heimdallrPath]) {
        hmdCheckAndCreateDirectory(heimdallrPath);
    }
    return [NSString stringWithFormat:@"%@/hermas", heimdallrPath];;
}

+ (NSUserDefaults *)customUserDefault {
    static NSUserDefaults *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NSUserDefaults alloc] initWithSuiteName:[HeimdallrUtilities customPlistSuiteComponent:kHermasPlistSuiteName]];
    });
    return instance;
};

+ (NSString *)urlStringWithHost:(NSString *)host path:(NSString *)path {
    NSDictionary *headerInfo = [HMDUploadHelper sharedInstance].headerInfo;
    NSDictionary *commonParams = [HMDInjectedInfo defaultInfo].commonParams ?: headerInfo; //防止业务层没配置通用参数，用headerInfo兜底，否则配置获取不正确
    
    // 添加query参数，兼容端容灾策略
    NSMutableDictionary *queryDic = [NSMutableDictionary dictionaryWithDictionary:commonParams];
    if (![queryDic valueForKey:@"update_version_code"]) {
        [queryDic setValue:headerInfo[@"update_version_code"] forKey:@"update_version_code"];
    }
    if (![queryDic valueForKey:@"os"]) {
        [queryDic setValue:headerInfo[@"os"] forKey:@"os"];
    }
    if (![queryDic valueForKey:@"aid"]) {
        [queryDic setValue:headerInfo[@"aid"] forKey:@"aid"];
    }
    if (!HMDIsEmptyDictionary(queryDic)) {
        NSString *queryString = [queryDic hmd_queryString];
        path = [NSString stringWithFormat:@"%@?%@", path, queryString];
    }
    
    NSString *url = [HMDURLHelper URLWithHost:host path:path];
    return url;
}

+ (BOOL)recordImmediately {
    return HMD_IS_DEBUG;
}

@end
