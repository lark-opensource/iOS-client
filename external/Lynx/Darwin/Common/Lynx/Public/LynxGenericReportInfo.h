//  Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXGENERICREPORTINFO_H_
#define DARWIN_COMMON_LYNX_LYNXGENERICREPORTINFO_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Some useful info stored in PageConfig, will be updated when onPageConfigDecoded:
// targetSdkVersion set by FE.
extern NSString *const kPropLynxTargetSDKVersion;
// template's page version set by FE.
extern NSString *const kPropLynxPageVersion;

@class LynxView;
@class LynxConfigInfo;
/**
 * Class hold some info like templateURL, thread strategy, pageConfig and etc.
 * It's used to report some common useful parameter when report event.
 * Mainly converted to JSONObject by toJSONObject() method,
 * and used as the third argument in API below:
 * @see ILynxApplogService#onReportEvent(String, JSONObject, JSONObject)
 */
@interface LynxGenericReportInfo : NSObject

/// create info object.
/// @param targetObj Target object of general information association, usually lynxView.
+ (instancetype)infoWithTarget:(NSObject *)targetObj;

/// Return json of LynxGenericReportInfo.
- (NSDictionary *)toJson;

/// Update template url.
/// Should be called from the main thread.
/// @param templateURL template url of lynx view.
- (void)updateLynxUrl:(NSString *)templateURL;

/// Update ThreadStrategy.
/// Should be called from the main thread.
- (void)updateThreadStrategy:(NSInteger)threadStrategyForRendering;

/// Update lepus type.
/// Should be called from the main thread.
/// @param enableLepusNG of tempmlate.
- (void)updateEnableLepusNG:(BOOL)enableLepusNG;

/// Update dsl type.
/// Should be called from the main thread.
/// @param dsl of tempmlate, as: tt, react and etc.
- (void)updateDSL:(NSString *)dsl;

/// Update property for key. If property or key is nil, do nothing.
/// Should be called from the main thread.
- (void)updatePropOpt:(id)value forKey:(NSString *)key;

/// Mark LynxGenericReportInfo immutable.
/// After marking as immutable, the update method should not be called, and it will not take effect
/// at the same time. The cost of calling the 'toJson' method becomes lower after being immutable.
/// Should be called from the main thread.
- (void)markImmutable;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_LYNXGENERICREPORTINFO_H_
