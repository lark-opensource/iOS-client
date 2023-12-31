// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/ios/piper/resource_loader_darwin.h"
#import "CoreJsLoaderManager.h"
#import "LynxEnv.h"
#import "LynxLog.h"
#import "LynxView.h"
#include "jsbridge/jsi/lynx_resource_setting.h"

namespace lynx {
namespace piper {

static NSString* FILE_SCHEME = @"file://";
static NSString* CORE_DEBUG_JS = @"lynx_core_dev";
static NSString* ASSETS_SCHEME = @"assets://";
static NSString* LYNX_ASSETS_SCHEME = @"lynx_assets://";
static NSString* ASSETS_CORE_SCHEME = @"assets://lynx_core.js";

/**
 * 1. the name is "lynx_core.js"
 *    i. if CoreJsLoaderManager loader is existed, use the loader to get core js path (in
 * LynxExample the path is nil) ii. if  devtool is enable, find the file in "LynxDebugResources"
 * bundle first, then in "LynxResources" bundle. (Android will check debugSource first) iii. else
 * devtool is disable, find the file in "LynxResources" bundle
 * 2. the name starts with "file://", try to use file system
 * 3. the name starts with "assets://" but doesn't equal to "assets://lynx_core.js", load file from
 * "Resource" bundle.
 * 4. the name starts with "lynx_assets://", the process is similar with "lynx_core.js" (the first
 * step)
 */
std::string JSSourceLoaderDarwin::LoadJSSource(const std::string& name) {
  NSString* str = [NSString stringWithUTF8String:name.c_str()];

  NSString* path = nil;
  NSBundle* frameworkBundle = [NSBundle mainBundle];
  if ([ASSETS_CORE_SCHEME isEqualToString:str]) {
    str = [str componentsSeparatedByString:@"."][0];
    NSURL* debugBundleUrl = [frameworkBundle URLForResource:@"LynxDebugResources"
                                              withExtension:@"bundle"];
    if (path == nil) {
      id<ICoreJsLoader> loader = [CoreJsLoaderManager shareInstance].loader;
      if (loader != nil) {
        path = [loader getCoreJs];
      }
    }

    if (path == nil && debugBundleUrl && LynxEnv.sharedInstance.devtoolEnabled) {
      NSBundle* bundle = [NSBundle bundleWithURL:debugBundleUrl];
      path = [bundle pathForResource:CORE_DEBUG_JS ofType:@"js"];
      if (path != nil) {
        LynxResourceSetting::getInstance()->is_debug_resource_ = true;
      }
    }

    if (path == nil) {
      NSURL* bundleUrl = [frameworkBundle URLForResource:@"LynxResources" withExtension:@"bundle"];
      NSBundle* bundle = [NSBundle bundleWithURL:bundleUrl];
      path = [bundle pathForResource:[str substringFromIndex:[ASSETS_SCHEME length]] ofType:@"js"];
    }
  } else if ([str length] > [FILE_SCHEME length] && [str hasPrefix:FILE_SCHEME]) {
    NSString* filePath = [str substringFromIndex:[FILE_SCHEME length]];
    if ([filePath hasPrefix:@"/"]) {
      path = filePath;
    } else {
      NSString* cachePath = [NSSearchPathForDirectoriesInDomains(
          NSCachesDirectory, NSUserDomainMask, YES) firstObject];
      path = [cachePath stringByAppendingPathComponent:filePath];
    }
  } else if ([str length] > [ASSETS_SCHEME length] && [str hasPrefix:ASSETS_SCHEME]) {
    NSRange range = [str rangeOfString:@"." options:NSBackwardsSearch];
    str = [str substringToIndex:range.location];
    path = [[NSBundle mainBundle]
        pathForResource:[@"Resource/"
                            stringByAppendingString:[str substringFromIndex:[ASSETS_SCHEME length]]]
                 ofType:@"js"];
  } else if ([str hasPrefix:LYNX_ASSETS_SCHEME]) {
    NSURL* bundleUrl = [frameworkBundle URLForResource:@"LynxResources" withExtension:@"bundle"];
    NSURL* debugBundleUrl = [frameworkBundle URLForResource:@"LynxDebugResources"
                                              withExtension:@"bundle"];
    return LoadLynxJSAsset(name, *bundleUrl, *debugBundleUrl);
  }
  if (path) {
    LLogInfo(@"LoadJSSource real path: %@", path);
    NSString* jsScript = [NSString stringWithContentsOfFile:path
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
    return jsScript.length ? std::string([jsScript UTF8String]) : "";
  }
  LLogError(@"LoadJSSource no corejs find with %@", str);
  return "";
}

/**
 * 1. If devtool is enabled, try to get the source path from LynxDebugResources.
 *   i. If [filename]_dev.js path can be found from "LynxDebugResources" bundle, use it, else try to
 * find [filename].js is available.
 * 2. If cannot find path from "LynxDebugResources", try to find whether [filename].js is available
 * in "LynxResources" bundle.
 */
std::string JSSourceLoaderDarwin::LoadLynxJSAsset(const std::string& name, NSURL& bundleUrl,
                                                  NSURL& debugBundleUrl) {
  NSString* str = [NSString stringWithUTF8String:name.c_str()];

  NSString* path = nil;
  NSRange range = [str rangeOfString:@"." options:NSBackwardsSearch];
  str = [str substringToIndex:range.location];
  // Under dev mode, try to load [filename]_dev.js first.
  // If the file is not available, try to load [filename].js.
  if (&debugBundleUrl && LynxEnv.sharedInstance.devtoolEnabled) {
    NSBundle* bundle = [NSBundle bundleWithURL:&debugBundleUrl];
    NSString* debugAssetName =
        [[str substringFromIndex:[LYNX_ASSETS_SCHEME length]] stringByAppendingString:@"_dev"];
    path = [bundle pathForResource:debugAssetName ofType:@"js"];
    if (path == nil) {
      path = [bundle pathForResource:[str substringFromIndex:[LYNX_ASSETS_SCHEME length]]
                              ofType:@"js"];
    }
  }

  if (path == nil) {
    NSBundle* bundle = [NSBundle bundleWithURL:&bundleUrl];
    NSString* filename = [str substringFromIndex:[LYNX_ASSETS_SCHEME length]];
    path = [bundle pathForResource:filename ofType:@"js"];
  }

  if (path) {
    LLogInfo(@"LoadLynxJSAsset real path: %@", path);
    NSString* jsScript = [NSString stringWithContentsOfFile:path
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
    return jsScript.length ? std::string([jsScript UTF8String]) : "";
  }

  LLogError(@"LoadLynxJSAsset no js file find with %@", str);
  return "";
}

}  // namespace piper
}  // namespace lynx
