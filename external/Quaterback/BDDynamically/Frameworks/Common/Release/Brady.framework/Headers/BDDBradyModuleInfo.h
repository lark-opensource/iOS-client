//
//  BDDBradyModuleInfo.h
//  BDBitcodeVM
//
//  Created by hopo on 2019/8/13.
//

#import <Foundation/Foundation.h>

#include <string>

typedef NS_ENUM(NSUInteger, KKBradyHookType) {
  KKBradyHookTypeVM_Remap,
  KKBradyHookTypeOBJC_msgforward
};

namespace bdlli {

struct LogConfiguration {
  /**
   是否输出 Module (load + hook) 日志
   */
  bool enableModInitLog = false;

  /**
   是否在控制台显示 NSLog 日志
   */
  bool enablePrintLog = false;

  /**
   是否在控制台显示 Instruction 执行日志
   */
  bool enableInstExecLog = false;

  /**
   是否在控制台显示 Instruction 执行调用堆栈日志
   */
  bool enableInstCallFrameLog = false;
};

struct ModuleConfiguration {
  std::string path;
  std::string name;
  int version = 0;
  int redirectHookCls = 0;
  int async = 0;
  int enableCallFuncLog = 0;
  KKBradyHookType hookType = KKBradyHookTypeVM_Remap;
  LogConfiguration logConfiguration;
  // guard by [BDBradyEngine::_contextsLock]
  int retryCount = 0;
  int loadInTime = 0;
  bool serializeNativeSymbolLookup = false;
  int bindSymbolMaxConcurrentOperationCount = 0;
};

} // namespace bdlli
