//
//  devtool_manager_iOS.mm
//  vmsdk
//  PIADebuggerHDTGlobalController calls PIADebuggerHDTHooker calls SetPauseAtEntry:enable
//  Created by Huang Zongshan on 2022/8/24.
//

#include "devtool/iOS/devtool_manager_iOS.h"

#ifdef __cplusplus  // for #include c++ files
#include "basic/log/logging.h"
#include "devtool/inspector_factory_impl.h"
#ifdef JS_ENGINE_V8
#include "devtool/v8/v8_inspector_handle.h"
#endif
#endif
#ifdef JS_ENGINE_QJS
#include "devtool/quickjs/qjs_inspector_handle.h"
#endif
@implementation DevtoolManagerIOS

+ (void)SetPauseAtEntry:(BOOL)enable {
  NSLog(@"[Devtool] Set pause at entry, enable = %@", enable ? @"YES" : @"NO");
#ifdef JS_ENGINE_V8
  vmsdk::devtool::v8::V8InspectorHandle::SetPauseAtEntry(enable);
#endif
#ifdef JS_ENGINE_QJS
  vmsdk::devtool::qjs::QjsInspectorHandle::SetPauseAtEntry(enable);
#endif
}

@end
