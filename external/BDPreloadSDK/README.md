# BDPreloadSDK - 主端统一预加载管理控件

https://bytedance.feishu.cn/space/doc/doccnv8OmZFJf2gDjw3b46kBYyd#

## 背景
![头条主端预加载策略梳理](https://bytedance.feishu.cn/space/sheet/shtcnTyRwsVSIWjyC1l3f1SlSEc#K9PV5F) 
主端内部各个业务在做性能优化的时候都采用了预加载能力，导致目前主端同时各个地方都可能有多个队列在预加载，预加载的策略也不统一，对整个应用内的性能与流量都会造成一定的损耗，基于此主端内预期提供一个整体的预加载管理控件，由各个业务接入。

主端内部做导流页资源预加载的时候实现了一套导流页资源预加载的能力，并在此之上实现了一套基本完善的预加载队列管理能力，后续接入了搜索场景站外页、搜索场景转码页、相关搜索转码页的预加载。计划以此能力作为基础，扩充能力，完成对主端内各个业务预加载场景的接入。

## 实现方案

仓库地址：https://code.byted.org/iOS_Library/BDPreloadSDK/

## 模块设计

### Core - 提供最基础的预加载队列的控制能力

提供基础的预加载任务投递功能，以及基础的预加载队列控制能力，包括取消，挂起，恢复等。

### WebView - WebView 资源预加载

提供 WebView 资源(html/css/js)预加载能力，内部提供简单的资源缓存，目前导流页，搜索站外页使用。

### TTNet - TTNet 预加载请求管理

### Image - 图片预加载请求管理

## 接入计划

1. 将 ByteWebView 内部预加载管理能力拆分独立成库，不影响原有逻辑的基础上先接入主端
2. 将 Feed 场景下的图文预加载管理接入 BDPreloadSDK，ByteWebView 内部 BDDetailContentPreloader 接入 BDPreloadSDK （付费专栏）
3. 调研各个业务场景的预加载机制策略，完善 SDK 能力，推动各个业务接入
SDK 预计提供的能力

[ ] 预加载队列任务管理
  [ ] 预加载等待数
  [x] 按批次后进先出
  [x] 并发数
  [x] 优先级
  [ ] 网络条件判断
  [x] 适时取消
[ ] 预加载上报统计
  [ ] 请求资源流量消耗
[ ] 接入场景
  [ ] Feed 转码页
  [x] 导流页
  [x] 搜索
  [ ] 付费专栏
  [ ] 微头条
  [ ] 问答
  [ ] 小视频
  [ ] 小游戏