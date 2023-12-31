//
//  BDPowerLogURLSessionDelegate.m
//  Jato
//
//  Created by ByteDance on 2022/10/16.
//

#import "BDPowerLogURLSessionDelegate.h"
#import "BDPowerLogURLSessionMonitor+Private.h"
@implementation BDPowerLogURLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [[BDPowerLogURLSessionMonitor sharedInstance] _taskEnd:task];
}

@end
