//
//  BDDYCSessionTask.h
//  BDDynamically
//
//  Created by zuopengliu on 13/3/2018.
//

#import <Foundation/Foundation.h>
#import "BDDYCModuleRequest.h"
#import <TTNetworkManager/TTNetworkManager.h>


@protocol BDDYCSessionTask <NSObject>
@required
- (void)cancel;

@required
@property (nonatomic, assign, getter=isCancelled) BOOL cancelled;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSMutableArray<id<BDDYCSessionTask>> *retryTasks;
@end


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

@class NSURLSessionTask;

#if BDAweme
__attribute__((objc_runtime_name("AWECFMuniments")))
#elif BDNews
__attribute__((objc_runtime_name("TTDMushroom")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDGorilla")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDCress")))
#endif
@interface BDDYCModuleListSessionTask : NSObject <BDDYCSessionTask>
@property (nonatomic, strong) BDDYCModuleRequest *request;
@property (nonatomic, strong) NSArray *moduleResponseList;

- (instancetype)initWithURLTask:(id )urlTask;
@end



__attribute__((objc_runtime_name("FBwolf")))

#if BDAweme
__attribute__((objc_runtime_name("AWECFVulpineMounting")))
#elif BDNews
__attribute__((objc_runtime_name("TTDBrambles")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSCaraway")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDChives")))
#endif
@interface BDDYCModuleSessionTask : NSObject <BDDYCSessionTask>
@property (nonatomic, strong) id moduleModel; /** BDDYCModuleModel */
@property (nonatomic, strong) id dycModule;

- (instancetype)initWithURLTask:(NSURLSessionTask *)urlTask;
@end



__attribute__((objc_runtime_name("FBgoose")))

#if BDAweme
__attribute__((objc_runtime_name("AWECFDaffodil")))
#elif BDNews
__attribute__((objc_runtime_name("TTDWheatStraw")))
#elif BDHotSoon
__attribute__((objc_runtime_name("TTDWheatStrawHunter")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDLeek ")))
#endif
@interface BDDYCSessionTask : NSObject <BDDYCSessionTask>
@property (nonatomic, strong) BDDYCModuleListSessionTask *moduleListTask;
@property (nonatomic, strong, readonly) NSArray<BDDYCModuleSessionTask *> *moduleTasks;

- (void)addModuleTask:(id<BDDYCSessionTask>)task forModuleModel:(id<NSCopying>)aModule;
- (BDDYCModuleSessionTask *)taskForModuleModel:(id<NSCopying>)aModule;
- (void)cancelTaskForModuleModel:(id<NSCopying>)aModule;
@end

#pragma clang diagnostic pop
