// Copyright 2020 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LynxConfig;
@class LynxLifecycleDispatcher;
@protocol LynxViewLifecycle;
@protocol LynxResourceProvider;

/*!
 LynxEnv  can be reused for multiple LynxViews
*/
@interface LynxEnv : NSObject

@property(nonatomic, readonly) LynxConfig *config;
@property(nonatomic, readwrite) NSString *locale;
@property(nonatomic, readonly) LynxLifecycleDispatcher *lifecycleDispatcher;
@property(nonatomic, readonly) NSDictionary *settings;
@property(nonatomic, readonly)
    NSMutableDictionary<NSString *, id<LynxResourceProvider>> *resoureProviders;
@property(nonatomic, readwrite) BOOL lynxDebugEnabled;
/*!
 * mDevtoolComponentAttach: indicates whether Devtool Component is attached to the host.
 * mDevtoolEnabled: control whether to enable Devtool Debug
 *
 * eg:
 * when host client attach Devtool, mDevtoolComponentAttach is set true by reflection to find class
 * defined in Devtool and now if we set mDevtoolEnabled switch true, Devtool Debug is usable. if set
 * mDevtoolEnabled false, Devtool Debug is unavailable.
 *
 * when host client doesn't attach Devtool, can't find class defined in Devtool and
 * mDevtoolComponentAttach is set false in this case, no matter mDevtoolEnabled switch is set true
 * or false ,Devtool Debug is unavailable
 *
 * To sum up, mDevtoolComponentAttach indicates host package type, online package without Devtool or
 * localtest with Devtool mDevtoolEnabled switch is controlled by user to enable/disable Devtool
 * Debug, and useless is host doesn't attach Devtool
 */
@property(nonatomic, readonly) BOOL devtoolComponentAttach;
@property(nonatomic, readwrite) BOOL devtoolEnabled;
@property(nonatomic, readwrite) BOOL devtoolEnabledForDebuggableView;
@property(nonatomic, readwrite) BOOL redBoxEnabled;
@property(nonatomic, readwrite) BOOL redBoxNextEnabled;
@property(nonatomic, readwrite) BOOL automationEnabled;
@property(nonatomic, readwrite) BOOL perfMonitorEnabled;
@property(nonatomic, readwrite) BOOL layoutOnlyEnabled;
@property(nonatomic, readwrite) BOOL autoResumeAnimation;
@property(nonatomic, readwrite) BOOL enableNewTransformOrigin;
@property(nonatomic, readwrite) BOOL recordEnable;

// use for ttnet by reject way .
@property(nonatomic, readwrite) void *cronetEngine;
// use for ttnet by reject way .
@property(nonatomic, readwrite) void *cronetServerConfig;

@property(nonatomic, readwrite) BOOL enableDevMenu
    __attribute__((deprecated("Use unified flag enableDevtoolDebug")));

@property(nonatomic, readwrite) BOOL enableJSDebug
    __attribute__((deprecated("Use unified flag enableDevtoolDebug")));

@property(nonatomic, readwrite) BOOL enableDevtoolDebug
    __attribute__((deprecated("Use devtoolEnabled")));

@property(nonatomic, readwrite) BOOL enableRedBox __attribute__((deprecated("Use redBoxEnabled")));

// values from settings
@property(nonatomic, readonly) BOOL switchRunloopThread;

+ (instancetype)sharedInstance;

- (void)prepareConfig:(LynxConfig *)config;
- (void)reportModuleCustomError:(NSString *)error;
- (void)onPiperInvoked:(NSString *)module
                method:(NSString *)method
              paramStr:(NSString *)paramStr
                   url:(NSString *)url
             sessionID:(NSString *)sessionID;
- (void)onPiperResponsed:(NSString *)module
                  method:(NSString *)method
                     url:(NSString *)url
                response:(NSDictionary *)response
               sessionID:(NSString *)sessionID;
- (void)updateSettings:(NSDictionary *)settings;
- (void)addResoureProvider:(NSString *)key provider:(id<LynxResourceProvider>)provider;

- (void)setDevtoolEnv:(BOOL)value forKey:(NSString *)key;
- (BOOL)getDevtoolEnv:(NSString *)key withDefaultValue:(BOOL)value;

- (void)setDevtoolEnv:(NSSet *)newGroupValues forGroup:(NSString *)groupKey;
- (NSSet *)getDevtoolEnvWithGroupName:(NSString *)groupKey;

- (void)setEnableRadonCompatible:(BOOL)value
    __attribute__((deprecated("Radon diff mode can't be close after lynx 2.3.")));
- (BOOL)getEnableRadonCompatible
    __attribute__((deprecated("Radon diff mode can't be close after lynx 2.3.")));

- (void)setEnableLayoutOnly:(BOOL)value;
- (BOOL)getEnableLayoutOnly;

- (void)setPiperMonitorState:(BOOL)state;
- (void)initLayoutConfig:(CGSize)screenSize;

- (void)setAutoResumeAnimation:(BOOL)value;
- (BOOL)getAutoResumeAnimation;

- (void)setEnableNewTransformOrigin:(BOOL)value;
- (BOOL)getEnableNewTransformOrigin;

- (void)setCronetEngine:(void *)engine;
- (void)setCronetServerConfig:(void *)config;

- (void)enableFluencyTracer:(BOOL)value;

+ (NSString *)getExperimentSettings:(NSString *)key;
+ (BOOL)getBoolExperimentSettings:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
