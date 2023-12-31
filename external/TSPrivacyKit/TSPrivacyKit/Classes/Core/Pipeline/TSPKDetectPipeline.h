//
//  TSPKDetectPipeline.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/28.
//

#import <Foundation/Foundation.h>

#import "TSPKEntryUnit.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKAspectModel.h"
@class TSPKHandleResult;
@class TSPKAPIModel;

@interface TSPKDetectPipeline : NSObject

+ (NSString *_Nullable)pipelineType;

+ (NSString *_Nullable)entryType;

+ (NSString *_Nullable)dataType;

+ (TSPKStoreType)storeType;

/// The api list of the pipeline hooked, combination of class APIs and instance APIs.
+ (NSArray<NSString *> * _Nullable)stubbedAPIs;
/// The c-api list of the pipeline hooked.
+ (NSArray<NSString *> * _Nullable)stubbedCAPIs;
/// The class api list of the pipeline hooked.
+ (NSArray<NSString *> * _Nullable) stubbedClassAPIs;
/// The instance api list of the pipeline hooked.
+ (NSArray<NSString *> * _Nullable) stubbedInstanceAPIs;

/// The class name of the pipeline hooked.
+ (NSString * _Nullable)stubbedClass;

+ (void)preload;

+ (BOOL)entryEnable;

- (TSPKEntryUnitModel *_Nullable)entryModel;

// delay fish hook task, it may cost time, delay its execute time
- (BOOL)deferPreload;

+ (TSPKHandleResult *_Nullable)handleAPIAccess:(NSString *_Nullable)api;
+ (TSPKHandleResult *_Nullable)handleAPIAccess:(NSString *_Nullable)api className:(NSString *_Nullable)className;
+ (TSPKHandleResult *_Nullable)handleAPIAccess:(NSString *_Nullable)api
                                     className:(NSString *_Nullable)className
                                        params:(NSDictionary *_Nullable)params;
+ (TSPKHandleResult *_Nullable)handleAPIAccess:(NSString *_Nullable)api
                                     className:(NSString *_Nullable)className
                                        params:(NSDictionary *_Nullable)params
                             customHandleBlock:(void (^ _Nullable)(TSPKAPIModel *_Nonnull apiModel))customHandleBlock;


+ (TSPKHandleResult *_Nullable)handleAPIAccess:(id _Nullable)arg1Inst AspectInfo:(TSPKAspectModel *_Nullable)aspectInfo;

+ (void)forwardCallInfoWithMethod:(nonnull NSString *)method
                          apiType:(nonnull NSString *)apiType
                     apiUsageType:(TSPKAPIUsageType)apiUsageType
                      isCustomApi:(BOOL)isCustomApi;

+ (void)forwardCallInfoWithMethod:(nonnull NSString *)method
                        className:(NSString *_Nullable)className
                     apiUsageType:(TSPKAPIUsageType)apiUsageType
                          hashTag:(nullable NSString *)hashTag
                    beforeOrAfter:(BOOL)beforeOrAfterCall;

+ (void)forwardBizCallInfoWithMethod:(NSString *_Nullable)method
                             apiType:(NSString *_Nullable)apiType
                            dataType:(NSString *_Nullable)dataType
                        apiUsageType:(TSPKAPIUsageType)apiUsageType
                             bizLine:(NSString *_Nullable)bizLine;

@end


