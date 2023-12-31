//
//  TTVidoEngineFetcherMaker.h
//  ABRInterface
//
//  Created by kun on 2021/1/19.
//

#import <Foundation/Foundation.h>
#import <MDLMediaDataLoader/AVMDLDataLoader.h>
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineModel.h"

NS_ASSUME_NONNULL_BEGIN

static const NSInteger MDL_RETRY_RESULT_ERROR = 0;
static const NSInteger MDL_RETRY_RESULT_SUCCESS = 1;
static const NSInteger MDL_RETRY_RESULT_SUCCESS_CACHE = 2;
@protocol TTVideoEngineMDLFetcherDelegate <NSObject>
- (NSString *)getId;
- (NSString *)getFallbackApi;
- (void)onMdlRetryStart:(NSError *)error;
- (void)onMdlRetryEnd;
- (void)onRetry:(NSError *)error;
- (void)onLog:(NSString *)message;
- (void)onError:(NSError *)error fileHash:(NSString *)fileHash;
- (void)onCompletion:(TTVideoEngineModel *)model newModel:(BOOL)newModel fileHash:(NSString *)fileHash;
@end


@interface TTVideoEngineFetcherMaker : NSObject <AVMDLiOSFetcherMakerInterface>

@property(nonatomic, strong)NSPointerArray *fetcherDelegateList;

//新版FetcherMaker做成全局单例
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;
+ (instancetype)instance;

- (void)storeDelegate:(id<TTVideoEngineMDLFetcherDelegate>)delegate;
- (void)removeDelegate:(id<TTVideoEngineMDLFetcherDelegate>)delegate;
- (id<TTVideoEngineMDLFetcherDelegate>)getMDLFetcherDelegate:(NSString*)engineId;

@end

NS_ASSUME_NONNULL_END
