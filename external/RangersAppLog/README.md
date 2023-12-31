# RangersAppLog

## 文档

- [iOS RangersAppLog 集成文档](https://bytedance.feishu.cn/wiki/wikcnfXlmdZU8FbuvsrNFx2iFUh)

- [版本记录](https://bytedance.feishu.cn/docs/doccnsaavDWkeCPniDKeF6YMgye)

## 简介

AppLog tob版本，包含以下功能

- [x] 设备注册激活
- [x] 埋点上报
- [x] 全埋点事件采集
- [x] 圈选

## 要求

- iOS 8.0+
- Xcode 9.0+

若遇到与XCode 12相关的编译/链接问题，可以反馈给组件维护人。

## 运行Example工程

**Example工程1**
+ clone工程
+ 切换到`Example`目录
+ `pod install`

**Example工程2**
+ clone工程
+ 切换到`ObjCExample`目录
+ `pod install`

## 接入方式

**建议使用Cocoapods接入**
### 不接入全埋点
```ruby
pod RangersAppLog,'5.6.0',:subspecs => [
    'Core',
    'Host/CN',  # 若您的APP的数据存储在中国, 则选择 Host/CN。否则选择相应地域的subspec。
    'Unique'  # 若需要采集IDFA，则引入Unique子库
]
```

### 接入全埋点
```ruby
pod RangersAppLog,'5.6.0',:subspecs => [
	'Core',
	'UITracker',
	'Picker',
    'Host/CN',  # 若您的APP的数据存储在中国, 则选择 Host/CN。否则选择相应地域的subspec。
    'Unique'  # 若需要采集IDFA，则引入Unique子库
]
```

### 子库说明
文档更新可能不及时，以podspec为准。

| subspec名称 | source_files                                                             | public_header_files      | Dependency                                | 备注                                   |
|-------------|--------------------------------------------------------------------------|--------------------------|-------------------------------------------|----------------------------------------|
| Core        | Classes/Utility Classes/Network Classes/Core Classes/Tables Classes/Data | Classes/Core/Header      | BDDataDecoratorTob                        | Lite版本； 注册激活和手动埋点功能      |
| Unique      | Unique                                                                   | Unique/*/.h              | RangersAppLog/Core                        | 采集IDFA，如果不希望读取IDFA，可不集成 |
| Log         | Log                                                                      | Log/*/.h                 | RangersAppLog/Core                        | ToB客户埋点验证                        |
| ET          | ET                                                                       | ET/*.h                   | RangersAppLog/Core                        | Lark用埋点验证，不ToB                  |
| Filter      | Filter                                                                   | Filter/*.h               | RangersAppLog/Core                        | 事件名过滤，不ToB                      |
| UITracker   | Classes/UITracker                                                        | Classes/UITracker/Header | RangersAppLog/Core                        | 全埋点版本                             |
| Picker      | Classes/Picker Classes/Libraries                                         | Classes/Picker/Header/   | RangersAppLog/UITracker RangersAppLog/Log | 圈选版本                               |
| Test        | Tests                                                                    |                          |                                           | 单元测试                               |
| Host        | 无                                                                       |                          | RangersAppLog/Core                        | 作为容器                               |
| Host/CN     | Host/CN/*                                                                |                          | 无                                        | 中国区域名                             |
| Host/VA     | Host/VA/*                                                                |                          | 无                                        | 美东域名                               |
| Host/SG     | Host/SG/*                                                                |                          | 无                                        | 东南亚域名                             |

## 对外发版方式
比如说要发版`5.7.0`
### 0. 先在组件平台上发版`5.7.0`
### 1. 下载组件平台编译产物
```
cd bitsBuilds
python3 batchDownload.py 5.7.0
```
编译产物会被下载到`bitBuilds/builds/platform5.7.0/RangersAppLog-Bits/RangersAppLog`
### 2. 基于前一步下载的编译产物，打出ToB Release包
```
cd buildReleaseZip
pytho3 buildReleaseZip.py ../bitsBuilds/builds/platform5.7.0/RangersAppLog-Bits/RangersAppLog /tmp/RangersAppLog
```
### 3. 更新二进制
在GitHub或TOS或[Rangers管理后台](https://data.bytedance.net/byterangers-admin/sdk)更新二进制。
### 4. 发布到Pod Spec仓库
### 5. 通知其他同学完成静态库发布。（i.e. 拆出 国内版、海外版、Lite版、全埋点版等版本...）

## 作者

- duanwenbin@bytedance.com
- zhangtianfu@bytedance.com
- chenyi.0@bytedance.com

## 维护者
- zhuyuanqing@bytedance.com

## 问题反馈交流群

[点击加入RangersAppLog Lark反馈群](lark://client/chatchatId=6673325644610273550)
