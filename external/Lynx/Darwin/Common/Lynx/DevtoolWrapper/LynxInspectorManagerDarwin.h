// Copyright 2019 The Lynx Authors. All rights reserved.
#include "config/config.h"
#if INSPECTOR_TEST

#import <Foundation/Foundation.h>
#import <Lynx/LynxBaseInspectorOwner.h>
#import <Lynx/LynxView.h>
#include "tasm/template_assembler.h"

NS_ASSUME_NONNULL_BEGIN

using lynx::tasm::HmrData;
@interface LynxInspectorManagerDarwin : NSObject

- (nonnull instancetype)initWithOwner:(id<LynxBaseInspectorOwner>)owner;

- (void)onTemplateAssemblerCreated:(intptr_t)ptr;

- (void)call:(NSString*)function withParam:(NSString*)params;

- (intptr_t)GetLynxDevtoolFunction;

- (intptr_t)GetFirstPerfContainer;

- (void)setLynxEnvKey:(NSString*)key withValue:(bool)value;

- (void)SendConsoleMessage:(NSString*)message
                 withLevel:(int32_t)level
              withTimStamp:(int64_t)timeStamp;

- (const std::shared_ptr<lynx::devtool::InspectorManager>&)getNativePtr;

- (intptr_t)getJavascriptDebugger;

- (intptr_t)getLepusDebugger:(NSString*)url;

- (intptr_t)createInspectorRuntimeManager;

- (void)HotModuleReplaceWithHmrData:(const std::vector<HmrData>&)component_datas
                            message:(const std::string&)message;

// methods below only support iOS platform now, empty implementation on macOS now
- (void)RunOnJSThread:(intptr_t)closure;

- (intptr_t)getTemplateApiDefaultProcessor;

- (intptr_t)getTemplateApiProcessorMap;

- (void)sendTouchEvent:(nonnull NSString*)type
                  sign:(int)sign
                     x:(int)x
                     y:(int)y
            onLynxView:(LynxView*)lynxview;

@end

NS_ASSUME_NONNULL_END

#endif
