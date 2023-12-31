// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxDevtoolDownloader.h"

@implementation LynxDevtoolDownloader

+ (void)download:(NSString*)url withCallback:(downloadCallback)callback {
  NSURL* nsurl = [NSURL URLWithString:url];
  NSURLRequest* request = [NSURLRequest requestWithURL:nsurl
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:2];
  [NSURLConnection
      sendAsynchronousRequest:request
                        queue:[[NSOperationQueue alloc] init]
            completionHandler:^(NSURLResponse* _Nullable response, NSData* _Nullable data,
                                NSError* _Nullable connectionError) {
              if (!connectionError) {
                callback(data, nil);
              } else {
                callback(data, connectionError);
              }
            }];
}

@end
