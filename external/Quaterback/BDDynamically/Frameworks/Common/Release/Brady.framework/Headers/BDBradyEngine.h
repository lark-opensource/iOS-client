//
//  BDBradyEngine.h
//  BDBitcodeVM
//
//  Created by 刘诗彬 on 2018/5/3.
//

#import <Foundation/Foundation.h>

#include <unordered_map>
#include <unordered_set>

#import "BDDBradyModuleInfo.h"

typedef NS_ENUM(NSInteger, BDLLIEngineLoadErrCode) {
  BDLLIEngineLoadErrCodeUnknow = -500,
  BDLLIEngineLoadErrFileNameInvalid  = -501, // file name is empty
  BDLLIEngineLoadErrCodeFilePathNotExist = -502, // file not exist
  BDLLIEngineLoadErrCodeFileHasLoad      = -503, // file has load
  BDLLIEngineLoadErrCodeVMCreationFail   = -504, // runtime enviroment(virtual machine) error
  BDLLIEngineLoadErrCodeBitcodeParseFail = -505, // parse syntax error
  BDLLIEngineLoadErrCodeBitcodeLoadFail  = -506, // load module(IR) fail
  BDLLIEngineLoadErrCodeBitcodeExecError = -507, // execute bitcode error
  BDLLIEngineLoadErrCodeUnloadFail       = -508, // unload module error
  BDLLIEngineLoadErrCodeOverflow     = -509, // unload module error
};

namespace bdlli {

class Context;

#pragma mark - BDBitcodeVM

class Engine {
public:
  static Engine &instance() {
    // C++11 static initializer is thread-safe.
    static Engine Singleton;
    return Singleton;
  }
  Engine(const Engine &) = delete;
  Engine(Engine &&) = delete;
  Engine &operator=(const Engine &) = delete;
  Engine &operator=(Engine &&) = delete;
  
  std::function<void(const char*)> LogCallback = nullptr;
  std::function<void(NSError *)> ExceptionHandler = nullptr;
  std::function<void(NSError *, const char *, int, long long)> LoadModuleErrorCallback = nullptr;
  
  void initialize();
  void shutdown();
  
  static void loadModuleAtPath(const char *Path);
  // unique_ptr is more appropriate here, however Obj-C blocks (GCD)
  // don't work with move-only C++ objects, hence we have to use shared_ptr.
  void loadModule(std::shared_ptr<ModuleConfiguration> Module);
  void unloadModule(const char *ModuleName, int ModuleVersion);
  
  void *lookupFunction(const char* FunctionName, const char *ModuleName,
                       int ModuleVersion);
  
private:
  Engine();
  
  void loadModuleInternal(std::shared_ptr<ModuleConfiguration> Module);
  void reportLoadingError(NSError *Error, ModuleConfiguration &Module,
                          long long Duration);
  
  bool Initialized;
  bool Enabled;
  dispatch_queue_t LoadQueue;
  dispatch_queue_t RetryQueue;
  pthread_mutex_t ContextsLock;
  
  //                                   Module name
  using ModuleMap = std::unordered_map<std::string,
  //                                                      contextsKeyForModule(module)
                                       std::unordered_set<std::string>>;
  
  ModuleMap WillLoadModules;
  ModuleMap DidLoadModules;
  std::unordered_map<std::string, int> WillCreateContext;
  
  // The reason to use a wrapper:
  // [Context] includes LLVM headers which we would NOT like to expose to user,
  // therefore we use a forward declaration for it.
  // However, [std::unique_ptr] expects a complete type when being declared...
  class ContextWrapper {
  public:
    ContextWrapper(Context *C) : C(C) {}
    ~ContextWrapper();
  private:
    Context *const C;
    Context *const& operator*() { return C; }
    Context *operator->() { return C; }
    ContextWrapper(const ContextWrapper &) = delete;
    ContextWrapper(ContextWrapper &&) = delete;
    ContextWrapper &operator=(const ContextWrapper &) = delete;
    ContextWrapper &operator=(ContextWrapper &&) = delete;
    friend class Engine;
  };
  std::unordered_map<std::string, std::unique_ptr<ContextWrapper>> Contexts;
};

} // namespace bdlli
