//
//  IESEffectDownloadProxy.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/10/21.
//

#import <Foundation/Foundation.h>
#import "LVEffectDataSource.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *LVEffectDownloadProxyErrorDomain;

@class LVEffectDataSourceEffectIDListRequest;
@class LVEffectDataSourceResourceIDListRequest;
@class LVEffectDataSourceFetchResponse;

typedef NSArray<LVEffectDataSourceFetchResponse *> LVEffectDataSourceFetchResponseArray;

typedef void(^LVEffectDataSourceResponseFetchCompletion)(LVEffectDataSourceFetchResponse *_Nonnull response);
typedef void(^LVEffectDataSourceResponseListFetchCompletion)(LVEffectDataSourceFetchResponseArray *_Nonnull responses);
typedef void(^LVEffectDataSourceDownloadFileCompletion)(NSString *_Nullable filePath, NSError *_Nullable error);
typedef void(^LVEffectDataSourceDownloadFileRetryProgressBlock)(CGFloat progress, NSInteger retryCount);
typedef void(^LVEffectDataSourceDownloadFileRetryCompletion)(NSString *_Nullable filePath, NSError *_Nullable error, NSInteger tryCount);

@protocol LVEffectValidateDelegate <NSObject>
@optional
-(NSError *_Nullable)validateEffect:(id<LVEffectDataSource>)effect filePath:(NSString *_Nullable)filePath;
@end

@protocol LVEffectDownloadProxyDelegate<NSObject>
@required
-(void)fetchEffectListWithEffectIDListRequest:(LVEffectDataSourceEffectIDListRequest *_Nonnull)request
                                   completion:(LVEffectDataSourceResponseFetchCompletion _Nonnull)completion;
-(void)fetchEffectListWithResourceIDListRequest:(LVEffectDataSourceResourceIDListRequest *_Nonnull)request
                                     completion:(LVEffectDataSourceResponseFetchCompletion _Nonnull)completion;

-(void)downloadEffectWithDataSource:(id<LVEffectDataSource> _Nonnull)effect
                         completion:(LVEffectDataSourceDownloadFileCompletion _Nullable)completion;
-(void)downloadEffectWithDataSource:(id<LVEffectDataSource>)effect
                         retryCount:(NSInteger)retryCount
                          validator:(id<LVEffectValidateDelegate> _Nullable)validator
                         completion:(LVEffectDataSourceDownloadFileRetryCompletion _Nullable)completion;

-(NSString *_Nullable)effectPathForEffectDataSource:(id<LVEffectDataSource> _Nonnull)effect;

-(BOOL)validateEffectWithDataSource:(id<LVEffectDataSource>)effect filePath:(NSString *_Nullable)filePath;

@end

@interface LVEffectDownloadProxy : NSObject

-(void)registerDelegate:(id<LVEffectDownloadProxyDelegate> _Nullable)delegate forPlatform:(LVEffectSourcePlatform)platform;
-(void)unregisterDelegateForPlatform:(LVEffectSourcePlatform)platform;

-(void)fetchEffectListWithEffectIDListRequests:(NSArray<LVEffectDataSourceEffectIDListRequest *> * _Nonnull)requests
                                    completion:(LVEffectDataSourceResponseListFetchCompletion _Nonnull)completion;
-(void)fetchEffectListWithResourceIDListRequests:(NSArray<LVEffectDataSourceResourceIDListRequest *> * _Nonnull)requests
                                      completion:(LVEffectDataSourceResponseListFetchCompletion _Nonnull)completion;

-(void)downloadEffectWithDataSource:(id<LVEffectDataSource>)effect
                         completion:(LVEffectDataSourceDownloadFileCompletion _Nullable)completion;
-(void)downloadEffectWithDataSource:(id<LVEffectDataSource>)effect
                         retryCount:(NSInteger)retryCount
                          validator:(id<LVEffectValidateDelegate> _Nullable)validator
                         completion:(LVEffectDataSourceDownloadFileRetryCompletion _Nullable)completion;

-(NSString *_Nullable)effectPathForEffectDataSource:(id<LVEffectDataSource> _Nonnull)effect;

-(BOOL)validateEffectWithDataSource:(id<LVEffectDataSource>)effect filePath:(NSString * _Nullable)filePath;

@end

@interface LVEffectDataSourceBaseRequest : NSObject
@property(nonatomic, assign) LVEffectSourcePlatform platform;
@end

@interface LVEffectDataSourceEffectIDListRequest : LVEffectDataSourceBaseRequest
@property(nonatomic, copy) NSArray<NSString *> *effectIDs;
@end

@interface LVEffectDataSourceResourceIDListRequest : LVEffectDataSourceBaseRequest
@property(nonatomic, copy) NSArray<NSString *> *resourceIDs;
@property(nonatomic, copy) NSString *pannel;
@end


@protocol LVEffectNotFoundEstimatable <NSObject>
+ (BOOL)estimateEffectNotFoundWhetherOrNotWithError:(NSError *)error;
@end

@interface LVEffectDataSourceFetchResponse : NSObject
@property(nonatomic, strong, nullable) NSArray<id<LVEffectDataSource>> *effects;
@property(nonatomic, strong, nullable) NSError *error;

+(void)registerEffectNotFoundEstimatorClass:(Class)estimatorClass;
+(void)unregisterEffectNotFoundEstimatorClass:(Class)estimatorClass;

// 资源是否下架
-(BOOL)isEffectNotFoundError;

-(instancetype)init NS_UNAVAILABLE;
-(instancetype)initWithEffects:(NSArray<id<LVEffectDataSource>> *_Nullable)effects error:(NSError *_Nullable)error;

+(instancetype)responseWithEffects:(NSArray<id<LVEffectDataSource>> * _Nullable)effects error:(NSError * _Nullable)error;
+(instancetype)responseWithEffects:(NSArray<id<LVEffectDataSource>> * _Nullable)effects;
+(instancetype)responseWithError:(NSError * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
