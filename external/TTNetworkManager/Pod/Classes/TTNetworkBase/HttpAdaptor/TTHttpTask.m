//
//  TTHttpTask.m
//  Pods
//
//  Created by gaohaidong on 9/22/16.
//
//

#import "TTHttpTask.h"

@implementation TTHttpTask

- (void)cancel {
    
}

- (void)suspend {
    
}

- (void)resume {
    
}

- (void)setPriority:(float)priority {
    
}

- (void)setThrottleNetSpeed:(int64_t)bytesPerSecond {

}

- (void)setHeaderCallback:(OnHttpTaskHeaderCallbackBlock)headerCallback {
    
}

- (void)setUploadProgressCallback:(OnHttpTaskProgressCallbackBlock)uploadProgressCallback {

}

- (void)setDownloadProgressCallback:(OnHttpTaskProgressCallbackBlock)downloadProgressCallback {

}

- (void)readDataOfMinLength:(NSUInteger)minBytes
                  maxLength:(NSUInteger)maxBytes
                    timeout:(NSTimeInterval)timeout
          completionHandler:(void (^)(NSData *, BOOL, NSError *, TTHttpResponse* response))completionHandler {
    
}

- (TTHttpRequest *)request {
    return nil;
}

@end
