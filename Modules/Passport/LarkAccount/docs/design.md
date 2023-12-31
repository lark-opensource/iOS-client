# SuiteLogin设计

## 登陆职责

> 提供并存储套件级别的用户基础信息以及设备基础信息，让接入放具备可以使用的基本能力

[x] AccountInfos
[x] CurrentAccount
[x] DeviceInfo
  [x] DeviceID
  [x] InstallID
[x] SessionKey (cookie)

> 支持多App共享/不共享登陆信息的能力

[x] login
[x] fastlogin
[x] logout

> 套件级别的用户信息变更通知

[ ] AccountInfoChangePush
[ ] AccountListChangePush

> 支持 共享/不共享 事务性切换账号的能力

[ ] switchAccount

## 设计思路

1. UI与逻辑分离，可以直接独立使用SuiteLoginSDK无UI化完成登陆流程
2. 请求接口化，方便后面接入到Rust的网络库
3. 最小化依赖，不依赖非必须的第三方库，保证体积够小
4. 因为服务端会限定不同情况下的可以执行的接口，因此核心逻辑基于状态机