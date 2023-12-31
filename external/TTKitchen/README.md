# Readme

TTKitchen 是面向公司各iOS业务线的SettingsSDK. 
设计文档见[这里](https://bytedance.feishu.cn/wiki/wikcnUgYsn4GdhvUl2u82gYJ2rd),
Changelog见[这里](https://code.byted.org/TTIOS/TTKitchen/blob/master/CHANGELOG.md).
如果有需求，欢迎点击[这里](https://code.byted.org/TTIOS/TTKitchen/issues)提交issue.

## Features
- [x] 读取做了强类型校验，并提供了兜底策略，避免存储、下发无效类型
- [x] 底层存储支持 YYCache 及 MMKV 两种方式，使用某种存储方式只需接入对应的 subspec 即可
- [x] 相比于早期的[TTSettingsManager](http://mobile.bytedance.net/components/TTSettingsManager?appId=1301&repoId=128&appType=1), 具有更简洁的接口
- [x] 支持settings平台V3接口的增量下发
- [x] 支持settings平台[长链接主动推送功能](https://bytedance.feishu.cn/docs/doccnwz92FvRmskqRohoPs9AIn4)
- [x] 支持settings平台[降级功能](https://bytedance.feishu.cn/docs/doccnXQobRlc50eWMiqQsMder2e)

## Installation

### Cocoapods
1. Add `pod 'TTKitchen', '~>3.0'` to your Podfile. By default, this only adds the subspec `Core`. To add other subspecs, please explicitly write in your podfile. E.g.
   ```Ruby
   pod 'TTKitchen', '~>3.0', :subspecs => [
       'Core', 
       'SettingsSyncer',        # For sending request to /service/settings/v3/
       'Browser'                # Recommended for INHOUSE debugging
   ]
2. Run `pod install` or `pod update`.
3. Import `<TTKitchen/TTKitchen.h>`.


## Subspecs
### Core
TTKitchen 的核心模块，提供了注册(configuration)、写入、读取等基础功能，可以使用此模块管理业务的轻量级数据的存取。
##### 注册(Configuration)
- 注册这一步，是为了确保用户明确地了解自己使用 TTKitchen 管理了什么样的数据，在注册时需要约定每个 key 对应的 value 的**类型、默认值、简介** 
- Key 值支持 '.' 语法来对应 Settings 中的子配置项
- 此外，TTKitchen提供了 freeze 功能，如果某个数据被标记为 freezed 后，数据的值在 App 一次生命周期中将被 freezed 为第一次读取的值

##### 写入/读取
- 存储兼容6种数据格式，String/int/boolean/float/Array/Dictionary。
- 读取做了强类型校验，避免存储、下发无效类型。
- 支持 基于YYCache 及 MMKV 的两种底层存储方式

### YYCache
使用基于SQLite的YYCache进行存储管理，具有高速二级缓存、线程友好，不需要担心性能问题和线程安全问题。

### MMKV
使用 MMKV 进行存储管理。


### SettingsSyncer
SettingsSyncer封装Core模块中的`-updateWithDictionary:`方法，提供了向服务端settings平台v3接口发送请求并更新本地存储的API。

### PersistentConnection
Settings 长链接推送功能模块。

### Browser
提供用于调试的可视化页面，展示已缓存的值：
- TTKitchenBrowserViewController：Settings查看界面
- TTKitchenEditorViewController：Settings编辑界面


## Authors
- chaisong
- lizhuopeng 
- zhoupeng.leo

