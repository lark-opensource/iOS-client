//
//  BDWebViewPreloadTask.h
//  Musically
//
//  Created by gejunchen.ChenJr on 2022/11/1.
//

#import <TTNetworkManager/TTNetworkDefine.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDWebViewPreloadTask : NSObject

@property (nonatomic, copy) TTNetworkChunkedDataHeaderBlock headerCallback;
@property (nonatomic, copy) TTNetworkChunkedDataReadBlock dataCallback;
@property (nonatomic, copy) TTNetworkObjectFinishBlockWithResponse callbackWithResponse;
@property (nonatomic, copy) TTNetworkURLRedirectBlock redirectCallback;
@property (nonatomic, strong) NSURLRequest *request;
@property (atomic, strong) NSDate *hitDate;
@property (atomic, strong) NSDate *startDate;
@property (atomic, strong) NSDate *responseDate;


/**
 @param request Current Url request.
 @param headerCallback TTNetworkChunkedDataHeaderBlock for TTNet.
 @param dataCallback TTNetworkChunkedDataReadBlock for TTNet.
 @param callbackWithResponse TTNetworkObjectFinishBlockWithResponse for TTNet.
 @param redirectCallback TTNetworkURLRedirectBlock for TTNet.
 @Note Please note that you must handle response data yourself through dataCallback if you want to get the whole data of the response.
 */
- (instancetype)initWithRequest:(NSURLRequest *)request
                 headerCallback:(nullable TTNetworkChunkedDataHeaderBlock)headerCallback
                   dataCallback:(nullable TTNetworkChunkedDataReadBlock)dataCallback
           callbackWithResponse:(nullable TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
               redirectCallback:(nullable TTNetworkURLRedirectBlock)redirectCallback;


- (BOOL)isValid;

- (void)setPriority:(float)priority;
- (void)setSkipSSLCertificateError:(BOOL)skipSSLCertificateError;

- (uint64_t)optimizedTime;
- (void)resume;
- (void)reResume;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
