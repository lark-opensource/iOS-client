//
//  BDLynxResourceDownloader.m
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#import "BDLynxResourceDownloader.h"
#if __has_include("BDLynxGurdModule.h")
#import "BDLynxGurdModule.h"
#endif
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import "BDLNetProtocol.h"
#import "BDLSDKManager.h"
#import "BDLSDKProtocol.h"

@interface BDLynxResourceDownloader ()

@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong) NSString *cacheDir;

@end

@implementation BDLynxResourceDownloader

+ (instancetype)sharedDownloader {
  static BDLynxResourceDownloader *downloader = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (!downloader) {
      downloader = [[BDLynxResourceDownloader alloc] init];
    }
  });
  return downloader;
}

- (instancetype)init {
  if (self = [super init]) {
    _session = [NSURLSession sharedSession];
    _cacheDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
        lastObject] stringByAppendingPathComponent:@"lynx_source"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:_cacheDir]) {
      [[NSFileManager defaultManager] createDirectoryAtPath:_cacheDir
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:NULL];
    }
  }
  return self;
}

- (void)downloadLynxFile:(NSString *)sourceURL
              completion:(void (^)(NSError *, NSString *))completion {
  if ([BDL_SERVICE_WITH_SELECTOR(BDLSDKProtocol, @selector(disableDownloadTemplate))
          disableDownloadTemplate]) {
    return;
  }

  NSString *destination = [_cacheDir
      stringByAppendingPathComponent:[NSString
                                         stringWithFormat:@"%@.js",
                                                          [self md5StringOfString:sourceURL]]];
  if ([[NSFileManager defaultManager] fileExistsAtPath:destination]) {
    if (completion) {
      completion(nil, destination);
    }
    return;
  }

  if (!sourceURL || ![sourceURL isKindOfClass:[NSString class]] || sourceURL.length == 0) {
    if (completion) {
      completion(nil, nil);
    }
    return;
  }

  if (BDL_SERVICE(BDLNetProtocol)) {
    [BDL_SERVICE_WITH_SELECTOR(BDLNetProtocol, @selector
                               (downloadTaskWithRequest:
                                             parameters:headerField:destination:completionHandler:))
        downloadTaskWithRequest:[NSURL URLWithString:sourceURL]
                     parameters:@{}
                    headerField:@{}
                    destination:[NSURL fileURLWithPath:destination]
              completionHandler:^(NSString *_Nonnull path, NSError *_Nonnull error) {
                if (completion) {
                  completion(error, path);
                }
              }];
  } else {
    NSLog(@"------ BDLNetProtocol not bind ------");
  }
}

- (NSString *)md5StringOfString:(NSString *)source {
  NSData *sourceData = [source dataUsingEncoding:NSUTF8StringEncoding];
  unsigned char result[CC_MD5_DIGEST_LENGTH];
  CC_MD5(sourceData.bytes, (CC_LONG)sourceData.length, result);
  return [NSString
      stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                       result[0], result[1], result[2], result[3], result[4], result[5], result[6],
                       result[7], result[8], result[9], result[10], result[11], result[12],
                       result[13], result[14], result[15]];
}

@end
