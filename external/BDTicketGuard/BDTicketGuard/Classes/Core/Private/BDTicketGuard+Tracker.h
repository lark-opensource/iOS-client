//
//  BDTicketGuard+Tracker.h
//  BDTicketGuard
//
//  Created by chenzhendong.ok@bytedance.com on 2022/7/13.
//

#import "BDTGDanceKit.h"
#import "BDTicketGuard.h"
#import "BDTGKeyPair.h"

@class BDTGCSRResult;

#define BDTGTrackSDKLaunch [BDTicketGuard trackSDKLaunch]
#define BDTGTrackGetPrivateKey(error, aKeyType, boolIsFromCache, intAttemptCount) [BDTicketGuard trackGetPrivateKeyWithError:error startTimestamp:startTimestamp keyType:aKeyType isFromCache:boolIsFromCache attemptCount:intAttemptCount]
#define BDTGTrackGetPrivateSuccess(loadTimes, boolIsFromCache) [BDTicketGuard trackGetPrivateKeySuccessWithTimes:loadTimes isFromCache:boolIsFromCache]

#define BDTGTrackGetPublicKey(error) [BDTicketGuard trackGetPublicKeyWithError:error startTimestamp:startTimestamp]
#define BDTGTrackGetCSRResult(csrResult) [BDTicketGuard trackGetClientCSRWithResult:csrResult]
#define BDTGTrackGetTicket(request, response, intHasLocalClientCert, intHasRemoteClientCert, intHasServerData) [BDTicketGuard trackGetTicketWithRequest:request response:response startTimestamp:startTimestamp hasLocalClientCert:intHasLocalClientCert hasRemoteClientCert:intHasRemoteClientCert hasServerData:intHasServerData]
#define BDTGTrackSignClientData(path, error, intAttemptCount) [BDTicketGuard trackSignClientDataForRequestPath:path error:error startTimestamp:startTimestamp attemptCount:intAttemptCount]
#define BDTGTrackGetCert(params, aError) [BDTicketGuard trackGetCertWithParams:params error:aError startTimestamp:startTimestamp]
#define BDTGTrackDecrypt(aError) [BDTicketGuard trackDecryptWithError:aError startTimestamp:startTimestamp]
#define BDTGTrackKeyCertNotMatch(isFromCache) [BDTicketGuard trackKeyCertNotMatch:isFromCache]
#define BDTGTrackAddGetTicketHeaders(aRequest, aError) [BDTicketGuard trackAddGetTicketHeaders:aRequest error:aError startTimestamp:startTimestamp]
#define BDTGTrackUseTicketIfFail(aRequest, aResponse) [BDTicketGuard trackUseTicketIfFail:aRequest response:aResponse]
#define BDTGTrackCreateSignature(result) [BDTicketGuard trackCreateSignatureResult:result startTimestamp:startTimestamp]
#define BDTGTrackPrivateKeyDidChange(keyType) [BDTicketGuard trackPrivateKeyDidChange:keyType]

NS_ASSUME_NONNULL_BEGIN


@interface BDTicketGuard (Tracker)

+ (void)trackSDKLaunch;

+ (void)trackGetPrivateKeyWithError:(NSError *_Nullable)error startTimestamp:(NSTimeInterval)startTimestamp keyType:(NSString *)keyType isFromCache:(BOOL)isFromCache attemptCount:(int)attemptCount;
+ (void)trackGetPrivateKeySuccessWithTimes:(NSInteger)loadTimes isFromCache:(int)isFromCache;

+ (void)trackGetPublicKeyWithError:(NSError *_Nullable)error startTimestamp:(NSTimeInterval)startTimestamp;

+ (void)trackGetClientCSRWithResult:(BDTGCSRResult *)result;

+ (void)trackGetTicketWithRequest:(id<BDTGHttpRequest>)request response:(id<BDTGHttpResponse>)response startTimestamp:(NSTimeInterval)startTimestamp hasLocalClientCert:(int)hasLocalClientCert hasRemoteClientCert:(int)hasRemoteClientCert hasServerData:(int)hasServerData;

+ (void)trackSignClientDataForRequestPath:(NSString *_Nullable)path error:(NSError *_Nullable)error startTimestamp:(NSTimeInterval)startTimestamp attemptCount:(int)attemptCount;

+ (void)trackGetCertWithParams:(NSDictionary *)params error:(NSError *)error startTimestamp:(NSTimeInterval)startTimestamp;

+ (void)trackDecryptWithError:(NSError *)error startTimestamp:(NSTimeInterval)startTimestamp;

+ (void)trackKeyCertNotMatch:(BOOL)isFromCache;

+ (void)trackAddGetTicketHeaders:(id<BDTGHttpRequest>)request error:(NSError *_Nullable)error startTimestamp:(NSTimeInterval)startTimestamp;

+ (void)trackUseTicketIfFail:(id<BDTGHttpRequest>)request response:(id<BDTGHttpResponse>)response;

+ (void)trackCreateSignatureResult:(BDTGSignatureResult *)result startTimestamp:(NSTimeInterval)startTimestamp;

+ (void)trackPrivateKeyDidChange:(NSString *)keyType;

@end

#define BDTGTrackFullPathSimple(eventType, aExtraInfo) BDTGTrackFullPathSimpleWithError(eventType, nil, aExtraInfo)
#define BDTGTrackFullPathSimpleWithError(aEventType, aError, aExtraInfo) BDTGTrackFullPath(@"all", aEventType, aError, aExtraInfo)


@interface BDTicketGuard (FullPathTracker)

+ (void)trackFullPathWithTicketName:(NSString *)ticketName eventType:(NSString *)eventType error:(NSError *_Nullable)error extraInfo:(NSDictionary *_Nullable)extraInfo;

@end


@interface BDTicketGuard (TrackerAdapter)


@end

NS_ASSUME_NONNULL_END
