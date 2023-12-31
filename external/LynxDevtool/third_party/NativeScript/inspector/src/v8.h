// Copyright 2011 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef V8_V8_H_
#define V8_V8_H_

// <Bytedance begin>
#include <map>
#include <set>
#include "src/base/platform/mutex.h"
// <Bytedance begin>
#include "src/globals.h"
#include "include/v8.h"

namespace v8 {

class Platform;
class StartupData;

namespace internal {

class Isolate;

class V8 : public AllStatic {
 public:
  // Global actions.

  static bool Initialize();
  static void TearDown();

  // Report process out of memory. Implementation found in api.cc.
  // This function will not return, but will terminate the execution.
  [[noreturn]] static void FatalProcessOutOfMemory(Isolate* isolate,
                                                   const char* location,
                                                   bool is_heap_oom = false);

  static void InitializePlatform(v8::Platform* platform);
  static void ShutdownPlatform();
  V8_EXPORT_PRIVATE static v8::Platform* GetCurrentPlatform();
  // Replaces the current platform with the given platform.
  // Should be used only for testing.
  V8_EXPORT_PRIVATE static void SetPlatformForTesting(v8::Platform* platform);

  static void SetNativesBlob(StartupData* natives_blob);
  static void SetSnapshotBlob(StartupData* snapshot_blob);
  // <Bytedance begin>
  static void DeInitializePlatform(v8::Platform* platform);
  static void BoundIsolateAndPlatform(
      v8::Isolate* isolate, v8::Platform* platform);
  static void UnboundIsolateAndPlatform(v8::Isolate* isolate);
  // <Bytedance end>

 private:
  static void InitializeOncePerProcessImpl();
  static void InitializeOncePerProcess();

  // v8::Platform to use.
  static v8::Platform* platform_;

  // <Bytedance begin>
  static std::map<v8::Isolate*, v8::Platform*>* platforms_map_;
  static std::set<v8::Platform*>* platforms_set_;
  static base::SharedMutex* shared_mutex_;
  // <Bytedance end>
};

}  // namespace internal
}  // namespace v8

#endif  // V8_V8_H_
