//
//  BDWebImageRequest+Progress.h
//  BDWebImage
//
//  Created by Bob on 2017/12/19.
//

#import "BDWebImageRequest.h"

@interface BDWebImageRequest (Progress)
- (void)_setReceivedSize:(int64_t)receivedSize andExpectedSize:(int64_t)expectedSize;

- (void)_receiveProgressData:(NSData *)currentReceiveData
                    finished:(BOOL)finished
                   taskQueue:(dispatch_queue_t)queue
                        task:(id<BDWebImageDownloadTask>)task;

@end
