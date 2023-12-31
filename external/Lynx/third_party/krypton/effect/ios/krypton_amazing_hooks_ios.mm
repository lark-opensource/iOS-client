#import <EffectPlatformSDK/EffectPlatform+AlgorithmModel.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/IESEffectManager.h>
#include <EffectSDK_iOS/bef_effect_api.h>
#include <JavaScriptCore/JSBase.h>
#import <SSZipArchive/SSZipArchive.h>
#include <mutex>
#include "krypton_amazing_hooks.h"

namespace lynx {
namespace canvas {
namespace effect {

void DownloadModel(void* userdata, const char* requirementsList[], int reqLength,
                   const char* modelNamesJson, bef_download_model_callback callback, void* ctx) {
  NSMutableArray* requiredAlgorithms = @[].mutableCopy;
  NSDictionary<NSString*, NSArray<NSString*>*>* modelNameAlgorithms = nil;
  for (int i = 0; i < reqLength; i++) {
    [requiredAlgorithms addObject:[NSString stringWithUTF8String:requirementsList[i]]];
  }
  if (modelNamesJson != nullptr) {
    NSString* jsonStr = [NSString stringWithUTF8String:modelNamesJson];
    if (jsonStr.length != 0) {
      NSError* err;
      NSData* jsondata = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
      NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:jsondata
                                                          options:NSJSONReadingMutableContainers
                                                            error:&err];
      if (!err) modelNameAlgorithms = dic;
    }
  }
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    [EffectPlatform fetchResourcesWithRequirements:requiredAlgorithms
                                        modelNames:modelNameAlgorithms
                                        completion:^(BOOL success, NSError* _Nonnull error) {
                                          if (error) {
                                            if (callback)
                                              callback(userdata, false, error.code,
                                                       [error localizedDescription].UTF8String);
                                          } else {
                                            if (callback) callback(userdata, success, 0, nullptr);
                                          }
                                        }];
  });
}

void DownloadSticker(void* userdata, const char* stickerId, bef_download_sticker_callback callback,
                     void* ctx) {
  std::string sticker_id(stickerId);
  NSMutableArray* effect_ids = @[].mutableCopy;
  [effect_ids addObject:[NSString stringWithUTF8String:stickerId]];
  [EffectPlatform
      fetchEffectListWithEffectIDS:effect_ids
                        completion:^(NSError* error, NSArray<IESEffectModel*>* effects,
                                     NSArray<IESEffectModel*>* bindEffects) {
                          if (error) {
                            callback(userdata, NO, 0, nullptr, error.code,
                                     [error localizedDescription].UTF8String);
                            return;
                          }
                          for (IESEffectModel* obj in effects) {
                            [EffectPlatform downloadEffect:obj
                                progress:^(CGFloat progress) {
                                  callback(userdata, NO, progress, nullptr, 0, nullptr);
                                }
                                completion:^(NSError* error, NSString* filepath) {
                                  if (error) {
                                    callback(userdata, NO, 0, nullptr, error.code,
                                             [error localizedDescription].UTF8String);
                                    return;
                                  }
                                  callback(userdata, YES, 1.0, filepath.UTF8String, 0, nullptr);
                                }];
                          }
                        }];
}

bef_resource_finder GetResourceFinder(void*) {
#if !TARGET_IPHONE_SIMULATOR
  return [EffectPlatform getResourceFinder];
#else
  return nullptr;
#endif
}

}  // namespace effect
}  // namespace canvas
}  // namespace lynx
