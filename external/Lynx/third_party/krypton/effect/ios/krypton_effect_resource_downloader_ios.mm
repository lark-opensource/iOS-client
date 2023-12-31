// Copyright 2022 The Lynx Authors. All rights reserved.

#import "krypton_effect_resource_downloader_ios.h"
#import <CommonCrypto/CommonDigest.h>
#import <EffectPlatformSDK/EffectPlatform+AlgorithmModel.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/IESEffectManager.h>
#import <EffectPlatformSDK/IESEffectUtil.h>
#import <Foundation/Foundation.h>
#import <SSZipArchive/SSZipArchive.h>

#include <vector>
#include "canvas/base/log.h"
#include "canvas/ios/canvas_app_ios.h"
#include "canvas/platform/camera_option.h"
#include "krypton_effect_wrapper.h"

using namespace lynx::canvas;

@interface KryptonEffectResourceDownloader : NSObject
@property(strong, nonatomic) NSURLSessionDownloadTask *task;
@property(copy, nonatomic) NSString *dirPath;
@property(copy, nonatomic) NSString *bundlePath;
@property(copy, nonatomic) NSString *zipPath;

@property(strong, nonatomic) id<LynxKryptonEffectHandlerProtocol> hanlder;
@end

@implementation KryptonEffectResourceDownloader

+ (instancetype)sharedInstance {
  static KryptonEffectResourceDownloader *instance;
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    instance = [[KryptonEffectResourceDownloader alloc] init];

    NSString *documentPath =
        NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    instance.dirPath = [documentPath stringByAppendingPathComponent:@"Krypton"];
    instance.bundlePath =
        [instance.dirPath stringByAppendingPathComponent:@"IESLiveEffectResource.bundle"];
    instance.zipPath =
        [instance.dirPath stringByAppendingPathComponent:@"IESLiveEffectResource.zip"];
  });
  return instance;
}

- (void)dealloc {
  if (self.task) {
    [self.task cancel];
    self.task = nil;
  }
}

- (void)setEffectHandler:(id<LynxKryptonEffectHandlerProtocol>)handler {
  _hanlder = handler;
}

- (void)downloadResource:(void (^)(NSString *, NSString *))completion {
  if ([[NSFileManager defaultManager] fileExistsAtPath:self.bundlePath]) {
    completion(_bundlePath, nil);
    return;
  }

  if (!_hanlder) {
    completion(nil, @"handler not exits");
    return;
  }

  // start download
  NSURL *url = [NSURL URLWithString:[_hanlder effectResourcePath]];
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                       timeoutInterval:20];
  if (self.task) {
    [self.task cancel];
    self.task = nil;
  }
  self.task = [[NSURLSession sharedSession]
      downloadTaskWithRequest:request
            completionHandler:^(NSURL *_Nullable location, NSURLResponse *_Nullable response,
                                NSError *_Nullable error) {
              if (!location || error) {
                completion(nil, [error description]);
                return;
              }
              @try {
                NSData *data = [NSData dataWithContentsOfURL:location];
                if (![[NSFileManager defaultManager] fileExistsAtPath:self.dirPath]) {
                  [[NSFileManager defaultManager] createDirectoryAtPath:self.dirPath
                                            withIntermediateDirectories:YES
                                                             attributes:nil
                                                                  error:nil];
                }
                [data writeToFile:self.zipPath atomically:YES];

                BOOL unZipSuccess = [SSZipArchive unzipFileAtPath:self.zipPath
                                                    toDestination:self.dirPath
                                                        overwrite:NO
                                                         password:nil
                                                  progressHandler:nil
                                                completionHandler:nil];
                [[NSFileManager defaultManager] removeItemAtPath:self.zipPath error:nil];
                if (!unZipSuccess ||
                    ![[NSFileManager defaultManager] fileExistsAtPath:self.bundlePath]) {
                  completion(nil, @"unzip failed");
                  return;
                };

                completion(self.bundlePath, nil);
              } @catch (NSException *exception) {
                completion(nil, [exception description]);
                return;
              }
            }];
  [self.task resume];
}

- (void)downloadModel:(NSArray<NSString *> *)requirement
       withCompletion:(void (^)(NSString *, NSString *))completion {
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    [EffectPlatform
        downloadRequirements:requirement
                  completion:^(BOOL success, NSError *_Nonnull error) {
                    if (error) {
                      completion(nil, [error description]);
                      return;
                    }
                    NSString *algorithmModelPath =
                        [[NSBundle mainBundle] pathForResource:@"EffectSDKResources"
                                                        ofType:@"bundle"];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:algorithmModelPath]) {
                      completion(nil, [algorithmModelPath stringByAppendingString:@" not exits"]);
                      return;
                    }

                    completion(algorithmModelPath, nil);
                  }];
  });
}

- (void)downloadSticker:(NSString *)sticker_id
           withCallback:(void (^)(BOOL success, NSError *error, NSString *filepath))callback {
  NSArray *effect_ids = [NSArray arrayWithObject:sticker_id];
  // [self setupEffectPlatform];
  [EffectPlatform fetchEffectListWithEffectIDS:effect_ids
                                    completion:^(NSError *error, NSArray<IESEffectModel *> *effects,
                                                 NSArray<IESEffectModel *> *bindEffects) {
                                      if (error) {
                                        callback(NO, error, nullptr);
                                        return;
                                      }
                                      for (IESEffectModel *obj in effects) {
                                        [EffectPlatform downloadEffect:obj
                                            progress:^(CGFloat progress) {
                                              KRYPTON_LOGW("progress = ") << progress;
                                            }
                                            completion:^(NSError *error, NSString *filepath) {
                                              if (error) {
                                                callback(NO, error, nullptr);
                                                return;
                                              }
                                              callback(YES, nullptr, filepath);
                                            }];
                                      }
                                    }];
}

@end

namespace lynx {
namespace canvas {
namespace effect {

EffectResourceDownloader *EffectResourceDownloader::Instance() {
  static EffectResourceDownloaderIOS *downloader = nullptr;
  if (!downloader) {
    downloader = new EffectResourceDownloaderIOS();
  }
  return downloader;
}

void EffectResourceDownloaderIOS::SetCanvasApp(const std::shared_ptr<CanvasApp> &canvas_app) {
  auto app = static_cast<CanvasAppIOS *>(canvas_app.get());
  [[KryptonEffectResourceDownloader sharedInstance] setEffectHandler:app->GetEffectHandler()];
}

void *EffectResourceDownloaderIOS::GetResourceFinder(void *effect_handler) {
  return reinterpret_cast<void *>([[IESEffectManager manager] getResourceFinder]);
}

void EffectResourceDownloaderIOS::DownloadBundles(EffectDownloadWithPathCallback callback) {
  [[KryptonEffectResourceDownloader sharedInstance]
      downloadResource:^(NSString *path, NSString *err) {
        if (err) {
          callback("", err.UTF8String);
          return;
        }

        callback(path.UTF8String, {});
      }];
}

void EffectResourceDownloaderIOS::DownloadModels(std::vector<const char *> requirements,
                                                 EffectDownloadWithPathCallback callback) {
  NSMutableArray *requiredAlgorithms = [NSMutableArray array];
  for (size_t i = 0; i < requirements.size(); i++) {
    [requiredAlgorithms addObject:[NSString stringWithUTF8String:requirements[i]]];
  }

  [[KryptonEffectResourceDownloader sharedInstance] downloadModel:requiredAlgorithms
                                                   withCompletion:^(NSString *path, NSString *err) {
                                                     if (err) {
                                                       callback("", err.UTF8String);
                                                       return;
                                                     }

                                                     callback(path.UTF8String, {});
                                                   }];
}

bool EffectResourceDownloaderIOS::DownloadSticker(const char *sticker_id,
                                                  std::unique_ptr<StickerDownloadCallbackType> cb) {
  return true;
}

}  // namespace effect
}  // namespace canvas
}  // namespace lynx
