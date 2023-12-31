//
//  BDPTTHttpDownloadTask.h
//  Timor
//
//  Created by annidy on 2019/10/9.
//

#import <Foundation/Foundation.h>

@class TTHttpTask;
@class TTHttpResponse;

NS_ASSUME_NONNULL_BEGIN

@interface BDPHttpDownloadTask : NSObject
@property TTHttpTask *ttTask;
@property TTHttpResponse *ttResponse;
@property NSURLSessionDataTask *nsTask;
@property NSHTTPURLResponse *nsResponse;
@property NSUInteger countOfBytesReceived;
@property (readonly) NSUInteger countOfBytesExpectedToReceive;
@property (readonly) NSInteger statusCode;
@property (readonly)  NSString * _Nullable host;
@property (nonatomic) CGFloat priority;

- (void)resume;
- (void)cancel;
- (void)suspend;


@end

NS_ASSUME_NONNULL_END
