// Copyright 2020 The Lynx Authors. All rights reserved.
#import "DevtoolAgentDarwin.h"
#import <Lynx/LynxRootUI.h>
#import <Lynx/LynxTemplateData+Converter.h>
#import <Lynx/LynxTraceController.h>
#import <Lynx/LynxUI.h>
#import <Lynx/LynxUIListInspector.h>
#import <Lynx/UIView+Lynx.h>
#import <mach/mach.h>
#import <objc/runtime.h>
#import <sys/utsname.h>
#import "LynxDeviceInfoHelper.h"
#import "LynxDevtoolEnv.h"
#import "LynxFPSTrace.h"
#import "LynxFrameViewTrace.h"
#import "LynxInspectorOwner.h"
#import "LynxInstanceTrace.h"
#import "LynxMemoryController.h"

#include "agent/devtool_agent_ng.h"

#if LYNX_ENABLE_TRACING
#include "base/trace_event/trace_controller.h"
#endif

#pragma mark - DevtoolAgentDarwin

#pragma mark - DevToolAgentImpl
namespace lynxdev {
namespace devtool {

class DevToolAgentNGImpl : public DevToolAgentNG {
 public:
  DevToolAgentNGImpl(DevtoolAgentDarwin* agent) { _agent = agent; }
  virtual ~DevToolAgentNGImpl() {}

  void SendResponse(const std::string& data) override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      [agent sendResponse:data];
    }
  }

  virtual void PageReload(bool ignore_cache, std::string template_binary,
                          bool from_template_fragments, int32_t template_size) override {
    __strong typeof(_agent) agent = _agent;
    if (agent) {
      NSString* nsBinary = nil;
      if (!template_binary.empty()) {
        nsBinary = [NSString stringWithCString:template_binary.c_str()
                                      encoding:NSUTF8StringEncoding];
      }
      [agent reloadPage:ignore_cache
           withTemplate:nsBinary
          fromFragments:from_template_fragments
               withSize:template_size];
    }
  }

  virtual void OnReceiveTemplateFragment(const std::string& data, bool eof) override {
    __strong typeof(_agent) agent = _agent;
    if (agent) {
      [agent onReceiveTemplateFragment:[NSString stringWithCString:data.c_str()
                                                          encoding:NSUTF8StringEncoding]
                               withEof:eof];
    }
  }

  virtual void Navigate(const std::string& url) override {}

  virtual lynx::base::PerfCollector::PerfMap* GetFirstPerfContainer() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      intptr_t res = [agent GetFirstPerfContainer];
      if (res) {
        return reinterpret_cast<lynx::base::PerfCollector::PerfMap*>(res);
      } else {
        return nullptr;
      }
    }
    return nullptr;
  }

  virtual void SetLynxEnv(const std::string& key, bool value) override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      [agent setLynxEnvKey:[NSString stringWithCString:key.c_str()
                                              encoding:[NSString defaultCStringEncoding]]
                 withValue:value];
    }
  }
#if LYNX_ENABLE_TRACING
  lynx::base::tracing::TraceController* GetTraceController() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      intptr_t res = [[LynxTraceController shareInstance] getTraceController];
      if (res) {
        return reinterpret_cast<lynx::base::tracing::TraceController*>(res);
      }
    }
    return nullptr;
  }

  lynx::base::tracing::TracePlugin* GetFPSTracePlugin() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      intptr_t res = [[LynxFPSTrace shareInstance] getFPSTracePlugin];
      if (res) {
        return reinterpret_cast<lynx::base::tracing::TracePlugin*>(res);
      }
    }
    return nullptr;
  }

  lynx::base::tracing::TracePlugin* GetFrameViewTracePlugin() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      intptr_t res = [[LynxFrameViewTrace shareInstance] getFrameViewTracePlugin];
      if (res) {
        return reinterpret_cast<lynx::base::tracing::TracePlugin*>(res);
      }
    }
    return nullptr;
  }

  lynx::base::tracing::TracePlugin* GetInstanceTracePlugin() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      intptr_t res = [[LynxInstanceTrace shareInstance] getInstanceTracePlugin];
      if (res) {
        return reinterpret_cast<lynx::base::tracing::TracePlugin*>(res);
      }
    }
    return nullptr;
  }
#endif
  virtual std::string GetSystemModelName() override {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* deviceModel = [NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding];

    return [deviceModel UTF8String];
  }

  virtual lynx::lepus::Value* GetLepusValueFromTemplateData() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nullptr) {
      intptr_t template_data = [agent GetLepusValueFromTemplateData];
      if (template_data != 0) {
        return reinterpret_cast<lynx::lepus::Value*>(template_data);
      }
    }
    return nullptr;
  }

  virtual lynx::lepus::Value* GetTemplateApiDefaultProcessor() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nullptr) {
      intptr_t default_processor = [agent GetTemplateApiDefaultProcessor];
      return reinterpret_cast<lynx::lepus::Value*>(default_processor);
    }
    return nullptr;
  }

  virtual std::unordered_map<std::string, lynx::lepus::Value>* GetTemplateApiProcessorMap()
      override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nullptr) {
      intptr_t processor_map = [agent GetTemplateApiProcessorMap];
      return reinterpret_cast<std::unordered_map<std::string, lynx::lepus::Value>*>(processor_map);
    }
    return nullptr;
  }

  virtual std::string GetTemplateConfigInfo() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      NSString* str = [agent getTemplateConfigInfo];
      if (str != nil) {
        return std::string([str UTF8String]);
      }
    }
    return "";
  }

  virtual std::string GetAppMemoryInfo() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      NSString* str = [agent getAppMemoryInfo];
      if (str != nil) {
        return std::string([str UTF8String]);
      }
    }
    return "";
  }

  virtual std::string GetAllTimingInfo() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      NSString* str = [agent getAllTimingInfo];
      if (str != nil) {
        return std::string([str UTF8String]);
      }
    }
    return "";
  }

  virtual std::string GetLynxVersion() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      NSString* str = [agent getLynxVersion];
      return std::string([str UTF8String]);
    }
    return "";
  }

  virtual void StartScreenCast(ScreenRequest request) override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      [agent startCasting:request.quality_ width:request.max_width_ height:request.max_height_];
    }
  }
  virtual void StopScreenCast() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      [agent stopCasting];
    }
  }

  virtual void RecordEnable(bool enable) override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      [agent recordEnable:enable];
    }
  }

  virtual void EmulateTouch(std::shared_ptr<lynxdev::devtool::MouseEvent> input) override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      [agent emulateTouch:input];
    }
  }
  virtual void DispatchMessageToJSEngine(const std::string& msg) override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      [agent DispatchMessageToJSEngine:msg];
    }
  }

  virtual void EnableTraceMode(bool enable_trace_mode) override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      [agent enableTraceMode:enable_trace_mode];
    }
  }

  void StartMemoryTracing() override { [[LynxMemoryController shareInstance] startMemoryTracing]; }

  void StopMemoryTracing() override { [[LynxMemoryController shareInstance] stopMemoryTracing]; }

  void StartMemoryDump() override {}

  void SendOneshotScreenshot() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      [agent sendOneshotScreenshot];
    }
  }

  virtual int FindUIIdForLocation(float x, float y, int uiSign) override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      return [agent findNodeIdForLocationWithX:x withY:y fromUI:uiSign];
    }
    return 0;
  }

  std::string GetUINodeInfo(int id) override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      NSString* res = [agent getUINodeInfo:id];
      if (res != nil) {
        return std::string([res UTF8String]);
      }
    }
    return "";
  }

  std::string GetLynxUITree() override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      NSString* res = [agent getLynxUITree];
      if (res != nil) {
        return std::string([res UTF8String]);
      }
    }
    return "";
  }

  int SetUIStyle(int id, std::string name, std::string content) override {
    __strong typeof(_agent) agent = _agent;
    if (agent != nil) {
      return [agent setUIStyle:id
                 withStyleName:[NSString stringWithUTF8String:name.c_str()]
              withStyleContent:[NSString stringWithUTF8String:content.c_str()]];
    }
    return -1;
  }

 private:
  __weak DevtoolAgentDarwin* _agent;
};

}  // namespace devtool
}  // namespace lynxdev

#pragma mark - DevtoolAgentDarwin
@implementation DevtoolAgentDarwin {
  __weak LynxInspectorOwner* _owner;
  __weak LynxInspectorManagerDarwin* _manager;
  std::shared_ptr<lynxdev::devtool::DevToolAgentBase> devtool_agent_;
}

- (instancetype)initWithInspectorOwner:(LynxInspectorOwner*)owner
                  withInspectorManager:(LynxInspectorManagerDarwin*)manager {
  self = [super init];
  if (self) {
    _owner = owner;
    _manager = manager;
    devtool_agent_ = std::dynamic_pointer_cast<lynxdev::devtool::DevToolAgentBase>(
        std::make_shared<lynxdev::devtool::DevToolAgentNGImpl>(self));
  }
  return self;
}

- (void)call:(NSString*)function withParam:(NSString*)params {
  devtool_agent_->Call(std::string([function UTF8String]), std::string([params UTF8String]));
}

- (void)sendResponse:(std::string)response {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner sendResponse:response];
  }
}

- (intptr_t)GetLynxDevtoolFunction {
  return devtool_agent_->GetLynxDevtoolFunction();
}

- (intptr_t)GetFirstPerfContainer {
  if (_manager) {
    return [_manager GetFirstPerfContainer];
  }
  return 0;
}

- (void)setLynxEnvKey:(NSString*)key withValue:(bool)value {
  if (_manager) {
    [_manager setLynxEnvKey:key withValue:value];
  }
}

- (void)dispatchMessage:(NSString*)message {
  if ([message containsString:@"sessionId"]) {
    // During lepus debugging, main thread might have been blocked and
    // wait for incoming Debugger.resume message.
    // In this case, we can not dispatch messages to main thread since
    // it will never get chance to be processed.
    devtool_agent_->DispatchMessage(std::string([message UTF8String]));
  } else {
    // Run on UI thread
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL),
               dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
      devtool_agent_->DispatchMessage(std::string([message UTF8String]));
    } else {
      dispatch_async(dispatch_get_main_queue(), ^() {
        self->devtool_agent_->DispatchMessage(std::string([message UTF8String]));
      });
    }
  }
}

- (void)startCasting:(int)quality width:(int)max_width height:(int)max_height {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner startCasting:quality width:max_width height:max_height];
  }
}

- (void)stopCasting {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner stopCasting];
  }
}

- (void)recordEnable:(bool)enable {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner enableRecording:enable];
  }
}

- (void)emulateTouch:(std::shared_ptr<lynxdev::devtool::MouseEvent>)input {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner emulateTouch:input];
  }
}

- (void)reloadPage:(BOOL)ignoreCache {
  [self reloadPage:ignoreCache withTemplate:nil fromFragments:NO withSize:0];
}

- (void)reloadPage:(BOOL)ignoreCache
      withTemplate:(NSString*)templateBin
     fromFragments:(BOOL)fromFragments
          withSize:(int32_t)size {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner reloadLynxView:ignoreCache
             withTemplate:templateBin
            fromFragments:fromFragments
                 withSize:size];
  }
}

- (void)onReceiveTemplateFragment:(NSString*)data withEof:(BOOL)eof {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner onReceiveTemplateFragment:data withEof:eof];
  }
}

- (void)dispatchConsoleMessage:(NSString*)message
                     withLevel:(int32_t)level
                  withTimStamp:(int64_t)timeStamp {
  devtool_agent_->DispatchConsoleMessage({[message UTF8String], level, timeStamp});
}

- (void)DispatchMessageToJSEngine:(std::string)message {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner DispatchMessageToJSEngine:message];
  }
}

- (intptr_t)GetLepusValueFromTemplateData {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    LynxTemplateData* templateData = [owner getTemplateData];
    if (templateData) {
      lynx::lepus::Value* value = LynxGetLepusValueFromTemplateData(templateData);

      return reinterpret_cast<intptr_t>(value);
    }
  }
  return 0;
}

- (intptr_t)GetTemplateApiDefaultProcessor {
  if (_manager) {
    return [_manager getTemplateApiDefaultProcessor];
  }
  return 0;
}

- (intptr_t)GetTemplateApiProcessorMap {
  if (_manager) {
    return [_manager getTemplateApiProcessorMap];
  }
  return 0;
}

- (NSString*)getTemplateConfigInfo {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    return [owner getTemplateConfigInfo];
  }
  return nil;
}

- (NSString*)getAppMemoryInfo {
  struct mach_task_basic_info info;
  mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
  kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
  if (kerr == KERN_SUCCESS) {
    NSDictionary* memoryStatus = @{
      @"resident" : @(info.resident_size),
      @"resident_max" : @(info.resident_size_max),
      @"virtual" : @(info.virtual_size)
    };
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:memoryStatus options:0 error:0];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
  return @"";
}

- (NSString*)getAllTimingInfo {
  __strong typeof(_owner) owner = _owner;
  if (owner and [owner getLynxView]) {
    NSDictionary* allTimingInfo = [[owner getLynxView] getAllTimingInfo];
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:allTimingInfo options:0 error:0];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
  return @"";
}

- (NSString*)getLynxVersion {
  return [LynxDeviceInfoHelper getLynxVersion];
}

- (void)DestroyDebug {
  if (devtool_agent_) {
    devtool_agent_->ResetTreeRoot();
  }
}

- (void)enableTraceMode:(BOOL)enable {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    [owner enableTraceMode:enable];
  }
}

- (void)sendOneshotScreenshot {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    // delay 1500ms to leave buffer time for rendering remote resources
    [owner sendCardPreviewWithDelay:1500];
  }
}

- (int)findNodeIdForLocationWithX:(float)x withY:(float)y fromUI:(int)uiSign {
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    return [owner findNodeIdForLocationWithX:x withY:y fromUI:uiSign];
  }
  return 0;
}

- (NSString*)getLynxUITree {
  NSString* res;
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    res = [owner getLynxUITree];
  }
  return res;
}

- (NSString*)getUINodeInfo:(int)id {
  NSString* res;
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    res = [owner getUINodeInfo:id];
  }
  return res;
}

- (int)setUIStyle:(int)id withStyleName:(NSString*)name withStyleContent:(NSString*)content {
  std::string res;
  __strong typeof(_owner) owner = _owner;
  if (owner) {
    return [owner setUIStyle:id withStyleName:name withStyleContent:content];
  }
  return -1;
}

@end
