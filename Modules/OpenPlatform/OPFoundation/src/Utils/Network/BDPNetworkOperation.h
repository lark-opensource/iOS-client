//
//  BDPNetworkOperation.h
//  Timor
//
//  Created by liubo on 2018/11/19.
//

#import <Foundation/Foundation.h>

@interface BDPNetworkOperation : NSOperation

@property (nonatomic, readonly) NSURLRequest *request;
@property (nonatomic, readonly) NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) NSData *responseData;

@property (nonatomic, strong) dispatch_queue_t completionQueue;
@property (nonatomic, strong) NSOutputStream *outputStream;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRequest:(NSURLRequest *)request NS_DESIGNATED_INITIALIZER;

- (void)setCompletionHandlerBlock:(void (^)(NSData *responseData, NSError *error))block;
- (void)setDownloadProgressBlock:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))block;

- (void)cancelConnection;

@end
