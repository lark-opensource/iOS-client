# NAPI

[Android tt-napi 组件](https://bits.bytedance.net/bytebus/components/components/detail/14171)

[iOS Napi 组件](https://bits.bytedance.net/bytebus/components/components/detail/14166)

[飞书交流群](https://applink.feishu.cn/client/chat/chatter/add_by_link?link_token=c08if6c1-d2a2-46f2-8074-d6a1213f850a)

基于 Node.js 的设计，实现的通用 JavaScript 绑定机制，支持不同 JavaScript 引擎作为底层实现，对插件二进制兼容。并实现了通用的线程调度机制，支持一套插件同时运行在不同 JS 运行时（小程序、Lynx 等）中。

[技术分享：JSBinding 调研与 NAPI 实践](https://bytedance.feishu.cn/docs/doccnaQ4umEJmHWNhTHN56cRg6j#)

## 接入

### 插件

如果你想要基于 NAPI 开发一款将 C++ 能力暴露到 JavaScript 的插件，可以参考 [插件接入文档](doc/addon.md)。

### JS 运行时

如果你是 JS 运行时的开发者，需要提供 NAPI 插件的运行环境，可以参考 [运行时接入文档](doc/runtime.md)。

## API 文档

- 数据类型
  - [Env](doc/env.md)
  - [CallbackInfo](doc/callbackinfo.md)
  - [Value](doc/value.md)
    - [Name](doc/name.md)
      - [Symbol](doc/symbol.md)
      - [String](doc/string.md)
    - [Number](doc/number.md)
    - [Boolean](doc/boolean.md)
    - [External](doc/external.md)
    - [Object](doc/object.md)
      - [Function](doc/function.md)
      - [Array](doc/array.md)
      - [ArrayBuffer](doc/arraybuffer.md)
      - [DataView](doc/dataview.md)
      - [TypedArray](doc/typedarray.md)
        - [TypedArrayOf](doc/typed_array_of.md)
      - [Promise](doc/promise.md)
  - [Reference](doc/reference.md)
    - [ObjectReference](doc/object_reference.md)
    - [FunctionReference](doc/function_reference.md)
  - [PropertyDescriptor](doc/property_descriptor.md)
  - [ScriptWrappable](doc/script_wrappable.md)
  - [ObjectWrap](doc/objectwrap.md)
    - [ClassPropertyDescriptor](doc/class_property_descriptor.md)
  - [Class](doc/class.md)
- [错误处理](doc/error_handle.md)
  - [Error](doc/error.md)
    - [TypeError](doc/typeerror.md)
    - [RangeError](doc/rangeerror.md)
  - [ErrorScope](doc/error_scope.md)
- [对象生命周期管理](doc/object_lifetime_management.md)
  - [HandleScope](doc/handle_scope.md)
  - [EscapableHandleScope](doc/escapable_handle_scope.md)
- [异步操作](doc/async_operations.md)
  - [AsyncWorker](doc/async_worker.md)
  - [ThreadSafeFunction](doc/threadsafe_function.md)
- [版本管理](doc/version_management.md)

## 示例

代码示例可以参见 [`testlib.cc`](test/testlib.cc) 中的单元测试。

目前有以下组件使用了 NAPI 进行开发，可以进行参考。

- [Helium 美颜模块](https://code.byted.org/toutiao-fe/helium/tree/dev/effect_render/src)
- [Sonic(WebGL2.0)](https://code.byted.org/toutiao-fe/Sonic)
- [PhysX](https://code.byted.org/developer/physics)
- [WebGPU](https://code.byted.org/developer/sonic-webgpu)
- [EffectSDK Amazing JavaScript Binding](https://bytedance.feishu.cn/docs/doccno2Vbos3MTb3VEtd1mx3lJb)

## 开发

1. 安装 [bazelisk](https://github.com/bazelbuild/bazelisk) （推荐将 `bazelisk` 链接为 `bazel`）
2. 执行 NAPI 测试。
   - `bazel test //test:napi-test-jsc`
   - `bazel test //test:napi-test-jsc`
   - `bazel test //test:napi-test-quickjs`

## Benchmark

### MacOS

- 执行 NAPI benchmark。
  - `bazel run -c opt //test:bench-v8`
  - `bazel run -c opt //test:bench-jsc`
  - `bazel run -c opt //test:bench-quickjs`

### Android

1. 构建安卓可执行文件。 `bazel build -c opt --config=android_arm64-v8a //test:bench-v8`
2. 使用 `./adbpush.sh` 将文件推入到安卓设备上，并打开 `adb shell`。
3. `cd /data/local/tmp/jsi-android-gen`
4. 执行目标测试，比如 `./test/bench-v8`
