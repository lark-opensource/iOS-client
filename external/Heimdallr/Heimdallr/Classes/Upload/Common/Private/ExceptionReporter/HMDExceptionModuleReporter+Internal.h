//
//  HMDExceptionModuleReporter+Internal.h
//  HeimdallrFinder
//
//  Created by xuminghao.eric on 2021/12/30.
//

#import "HMDExceptionModuleReporter.h"
//#include <pthread.h>

NS_ASSUME_NONNULL_BEGIN

#define  WAIT_FOR_REPORT [self.condtion lock]; while(self.reporting) [self.condtion wait]; self.reporting = YES; [self.condtion unlock];
#define    FINISH_REPORT [self.condtion lock]; self.reporting = NO; [self.condtion signal]; [self.condtion unlock];

typedef void (^HMDExceptionUploadCompletion)(BOOL isSuccess, BOOL isDropData, NSDictionary * _Nullable responseDict);

@interface HMDExceptionModuleReporter()
{
@public
    pthread_rwlock_t rwlock;
}
@property (nonatomic, strong) NSMutableSet<id<HMDExceptionReporterDataProvider>> *exceptionModules;
@property (nonatomic, strong) dispatch_queue_t exceptionReportQueue;
@property (nonatomic, strong) dispatch_queue_t exceptionResponseQueue;
@property (nonatomic, strong) NSCondition *condtion;
@property (nonatomic, assign, getter=isReporting) BOOL reporting;

- (void)uploadDataWithDataDicts:(NSArray<NSDictionary *> * _Nonnull)dataDicts
                          appID:(NSString * _Nullable)appID
                    urlProvider:(id<HMDURLProvider> _Nullable)urlProvider
                     completion:(HMDExceptionUploadCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
