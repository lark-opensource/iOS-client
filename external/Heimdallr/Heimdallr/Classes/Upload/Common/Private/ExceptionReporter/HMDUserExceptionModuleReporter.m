//
//  HMDUserExceptionModuleReporter.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/6/10.
//

#import "HMDUserExceptionModuleReporter.h"
#if RANGERSAPM
#import "HMDUserExceptionModuleReporter+RangersAPMURLProvider.h"
#else
#import "HMDUserExceptionModuleReporter+HMDURLProvider.h"
#endif
#import "HMDExceptionModuleReporter+Internal.h"
// Utility
#import "pthread_extended.h"
// Config
#import "HMDConfigManager.h"

@implementation HMDUserExceptionModuleReporter

- (id<HMDURLProvider>)moduleURLProvier {
    return self;
}

#if RANGERSAPM
- (void)_reportExceptionData {
    pthread_rwlock_rdlock(&rwlock);
    NSArray<id<HMDExceptionReporterDataProvider>> *modules = [self.exceptionModules allObjects];
    pthread_rwlock_unlock(&rwlock);
    
    for (id<HMDExceptionReporterDataProvider> module in modules) {
        if ([module respondsToSelector:@selector(exceptionType)] && [module exceptionType] == HMDUserExceptionType && [module respondsToSelector:@selector(exceptionDataForAppID:)]) {
            NSArray *allUserExceptionAids = [[HMDConfigManager sharedInstance] userExceptionAppIDs];
            
            [allUserExceptionAids enumerateObjectsUsingBlock:^(id  _Nonnull appID, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([appID isKindOfClass:NSString.class]) {
                    
                    WAIT_FOR_REPORT
                    NSArray *uploadDataDicts = [module exceptionDataForAppID:appID]; // 调用UserException接口获取对应aid的数据
                    if (!uploadDataDicts || uploadDataDicts.count <= 0) {
                        FINISH_REPORT
                        return;
                    }
                    
                    [self uploadDataWithDataDicts:uploadDataDicts appID:appID urlProvider:self completion:^(BOOL isSuccess, BOOL isDropData, NSDictionary * _Nullable responseDict) {
                        // 调用UserException接口清理对应数据
                        if ([module respondsToSelector:@selector(exceptionReporterDidReceiveResponse:)]){
                            [module exceptionReporterDidReceiveResponse:isSuccess];
                        }
                        FINISH_REPORT;
                    }];
                }
            }];
            break;
        }
    }
}
#endif

@end
