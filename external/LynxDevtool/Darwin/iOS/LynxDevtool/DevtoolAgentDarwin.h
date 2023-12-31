// Copyright 2020 The Lynx Authors. All rights reserved.

#import <Lynx/LynxInspectorManagerDarwin.h>
#import <UIKit/UIKit.h>
#import "DevtoolRuntimeManagerDarwin.h"
#import "LynxInspectorOwner.h"
#import "lepus/value.h"

@interface DevtoolAgentDarwin : NSObject

// clang-format off
- (instancetype)initWithInspectorOwner:(LynxInspectorOwner*)owner withInspectorManager:(LynxInspectorManagerDarwin*)manager;
// clang-format on

- (void)call:(NSString*)function withParam:(NSString*)params;

- (void)dispatchMessage:(NSString*)message;

- (void)sendResponse:(std::string)response;

- (intptr_t)GetLynxDevtoolFunction;

- (intptr_t)GetFirstPerfContainer;

- (void)setLynxEnvKey:(NSString*)key withValue:(bool)value;

- (void)startCasting:(int)quality width:(int)max_width height:(int)max_height;

- (void)stopCasting;

- (void)recordEnable:(bool)enable;

- (void)emulateTouch:(std::shared_ptr<lynxdev::devtool::MouseEvent>)input;

- (void)reloadPage:(BOOL)ignoreCache;

- (void)reloadPage:(BOOL)ignoreCache
      withTemplate:(nullable NSString*)templateBin
     fromFragments:(BOOL)fromFragments
          withSize:(int32_t)size;

- (void)onReceiveTemplateFragment:(NSString*)data withEof:(BOOL)eof;

- (intptr_t)GetLepusValueFromTemplateData;

- (intptr_t)GetTemplateApiDefaultProcessor;

- (intptr_t)GetTemplateApiProcessorMap;

- (NSString*)getTemplateConfigInfo;

- (NSString*)getAppMemoryInfo;
- (NSString*)getAllTimingInfo;

- (NSString*)getLynxVersion;

- (void)dispatchConsoleMessage:(NSString*)message
                     withLevel:(int32_t)level
                  withTimStamp:(int64_t)timeStamp;

- (void)DispatchMessageToJSEngine:(std::string)message;

- (void)DestroyDebug;

- (void)enableTraceMode:(BOOL)enable;

- (void)sendOneshotScreenshot;

- (int)findNodeIdForLocationWithX:(float)x withY:(float)y fromUI:(int)uiSign;

- (NSString*)getLynxUITree;

- (NSString*)getUINodeInfo:(int)id;

- (int)setUIStyle:(int)id withStyleName:(NSString*)name withStyleContent:(NSString*)content;

@end
