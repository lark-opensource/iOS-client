//
//  BDPTTHttpDownloadTask.m
//  Timor
//
//  Created by annidy on 2019/10/9.
//

#import "BDPHttpDownloadTask.h"
#import <TTNetworkManager/TTHttpTask.h>
#import <TTNetworkManager/TTHttpResponse.h>


@implementation BDPHttpDownloadTask

- (void)setPriority:(CGFloat)priority
{
    if (self.nsTask) {
        self.nsTask.priority = priority;
    }
    if (self.ttTask) {
        [self.ttTask setPriority:priority];
    }
    _priority = priority;
}


- (NSInteger)statusCode {
    if (self.ttResponse) {
        return self.ttResponse.statusCode;
    }
    if (self.nsResponse) {
        return self.nsResponse.statusCode;
    }
    return 503;
}

- (NSString *)host {
    if (self.ttResponse) {
        return self.ttResponse.URL.host;
    }
    if (self.nsResponse) {
        return self.nsResponse.URL.host;
    }
    return nil;
}

- (void)resume {
    if (self.nsTask) {
        [self.nsTask resume];
    }
    if (self.ttTask) {
        [self.ttTask resume];
    }
}

- (void)cancel {
    if (self.nsTask) {
        [self.nsTask cancel];
    }
    if (self.ttTask) {
        [self.ttTask cancel];
    }
}

- (void)suspend {
    if (self.nsTask) {
        [self.nsTask suspend];
    }
    if (self.ttTask) {
        [self.ttTask suspend];
    }
}

- (NSUInteger)countOfBytesExpectedToReceive {
    if (self.nsTask) {
        return self.nsTask.countOfBytesExpectedToReceive;
    }
    if (self.ttResponse) {
        id length = self.ttResponse.allHeaderFields[@"content-length"];
        if ([length isKindOfClass:[NSString class]])
            return [(NSString *)length integerValue];
        if ([length isKindOfClass:[NSNumber class]])
            return [(NSNumber *)length integerValue];
    }
    return 0;
}

@end
