# BDALog
⬇️⬇️更详细的使用文档请见下面⬇️⬇️：
[BDALog详细介绍](https://slardar.bytedance.net/docs/115/150/66382/)
这里只写了BDALog的基础操作和版本更新。

## 简介
`BDALog` 是iOS端高性能的运行期日志组件，结合云控可定向回捞日志。
请注意：BDALog组件只有写入日志的操作，不包含主动上传用户日志和在Slardar上下发命令回捞用户日志的操作。

## 特性
- [x] `性能高效`，相比于直接写入文件或数据库I/O操作少CPU使用率低。性能测试详情参见[性能测试报告](https://docs.bytedance.net/doc/9sdBkwjdJUtZpJC2zpDHtg)
- [x] `日志不丢失`，使用mmap缓存机制，确保日志即使在crash情况下也不丢失
- [x] `安全`，使用ecdh +tea的混合加密算法对单行日志加密
- [x] `磁盘占用少`，使用流式压缩对单行日志压缩，压缩率为25倍（2.5M原始日志被压缩写入文件后文件大小为100k）
- [x] `支持C和C++`
- [x] `结合云控定向回捞日志`，通过云控下发指令定向回捞指定用户日志并可在[sladar](https://slardar.bytedance.net/node/app_detail/?aid=13&os=iOS#/dashboard)上查看日志
- [x] `日志分level`，通过level控制日志输入输出，并可在[sladar](https://slardar.bytedance.net/node/app_detail/?aid=13&os=iOS#/dashboard)上筛选指定level日志
- [x] `可完全替代NSLog`，BDALog日志可输出到console并提供比NSLog更详细的信息，API使用跟NSLog保持一致
- [x] `轻量`，BDAlog不依赖任何非系统库，整个仓库大小不到2M
- [x] `简单易用`，提供与NSLog使用完全一致的宏写入log，日志缓存完全由SDK管理
- [x] `自定义加密`，支持默认方式加密和app自定义公私钥加密

##  安装
 
```ruby
pod 'BDALog'
```

## 版本要求

+ iOS 8.0+/9.0+
+ Xcode版本：10.0+/9.0+

## 运行Example工程

+ clone工程
+ 切换到`Example`目录
+ `pod install`

## 接入方式

CocoaPods接入方式支持：

+ [x] 源码支持
+ [x] 二进制支持
+ [ ] 混淆支持

Swift支持：

+ [ ] 原生支持
+ [x] 需要使用Modular Header
+ [x ] 需要使用Bridging Header

## 代码示例
更多自定义初始化/功能/Swift使用操作请见[ALog使用示例](https://slardar.bytedance.net/docs/115/150/66382/#%E4%BD%BF%E7%94%A8%E7%A4%BA%E4%BE%8B)。

### 1. 引入 `#import "BDAgileLog.h"`头文件（Required）

### 2. 初始化SDK（Required）
```objectivec
//建议在-application：didFinishLaunchingWithOptions：初始化SDK
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [directory stringByAppendingPathComponent:@"alog"];
    
    //初始化alog
    alog_open_default([path UTF8String], "BDALog");
    
    //设置log等级
    alog_set_log_level(kLevelAll);
    
    //是否在console输出
#ifdef DEBUG
    alog_set_console_log(true);
#endif
    
    return YES;
}
```

### 3. 写入log（Required）
```objectivec
//建议使用提供宏写入log，用法与NSLog一致
NSString *log = @"log -------end";
NSString *name = @"[hopo]";
//debug log
BDALOG_DEBUG(@"%@%@%@",log, name,log)

//info log
BDALOG_INFO(log);

//warn log
BDALOG_WARN(log);

//error log
BDALOG_ERROR(log);

//fatal log
BDALOG_FATAL(log);

//自定义level
BDALOG(kLevelWarn, @"%@%@%@",log, name,log);

//自定义level和tag
BDALOG_TAG(kLevelWarn, @"tag", @"%@%@%@",log, name,log);
            
//写入json          
BDALOG_FATAL(@"%@",@{@"test":@"1",
                     @"test1":@"2",
                     @"test2":@"3",
                     @"test3":@{@"test":@"1",
                     @"test1":@"2",},
                     @"test4":@[@"number_1",@"number_2",@"number_3",@"number_4",@"number_5",@"number_6",@"number_7"]
                       });

//写入数组
BDALOG_ERROR(@"%@",@[@"number_1",@"number_2",@"number_3",@"number_4",@"number_5",@"number_6",@"number_7"])
```

### 4. 手动将log写入文件(Optional)
```objectivec
/** 将log flush到目标文件*/

//异步flush
alog_flush();

//同步flush
alog_flush_sync();
```

### 5. 关闭SDK（Required）
```objectivec
//建议在-applicationWillTerminate关闭alog
- (void)applicationWillTerminate:(UIApplication *)application
{
    //关闭alog打开的文件
    alog_close();
}
```

## Decode

可至Slardar平台的左侧菜单栏 `单点追查` - `Alog解密`里上传.alog文件查看。
[Alog解密](https://slardar.bytedance.net/node/app_detail/?aid=13&os=iOS&region=cn&lang=zh-Hans#/track/testUpload)

## 日志回捞

日志是不会主动上报的，如果需要回捞日志，目前需要依赖 `Heimdallr` SDK 和 `Slardar` 平台实现。
，主要是Heimdallr中的云控子模块，云控子模块的具体接入方式可以参考 ：[云控集成指南](https://slardar.bytedance.net/docs/115/150/2722/)
日志回捞指令可在Slardar平台的左侧菜单栏 `单点追查` - `命令下发`中下发。
注意：Heimdallr `0.4.7` 版本以上才支持该功能

## 主动上报

如果需要客户端在Crash后自动上报日志或者主动上报某一时间段的日志，需要依赖Heimdallr的Alog子模块，具体接入方式可以参考：[Alog集成指南](https://slardar.bytedance.net/docs/115/150/2398/)

## 上报日志检索

回捞日志和主动上报的日志都可以在Slardar平台的左侧菜单栏 `单点追查` - `日志文件检索`中查到。

## 其他方案
日志写入方案/日志压缩方案/日志格式/日志展现形式/文件名格式/压缩策略/加密策略/上报策略/分片策略/淘汰策略请见[ALog方案设计](https://slardar.bytedance.net/docs/115/150/66382/#%E6%96%B9%E6%A1%88%E8%AE%BE%E8%AE%A1)。

## Author

胡波, hubo.christyhong@bytedance.com
张迅, zhangxun.kilroy@bytedance.com

## License

BDALog is available under the MIT license. See the LICENSE file for more info.

## Q&A
### 日志写入.alog文件的时机是什么？
写入文件的几个时机，这里.mmap2文件是写入log的buffer文件：
* 调用 `alog_open_default` 一系列的初始化函数会将上次缓存未写入的.mmap2文件log同步到.alog文件
* 调用 `alog_flush` 函数`异步`将.mmap2文件log同步到.alog文件
* 调用 `alog_flush_sync` 函数`同步`将.mmap2文件log同步到.alog文件
* .mmap2文件log大小达到一定阈值时同步log到.alog文件
* 写入log的级别为`FATAL`的时候同步log到.alog文件

### 日志缓存文件的淘汰策略是什么？
SDK内部从`时间`和`空间`两个维度做了缓存淘汰策略，如使用`alog_open_default`初始化ALog，则默认最大缓存`50M`缓存有效期`7天`。业务方可使用`alog_open`自定义缓存大小和缓存有效期。

### 基础库怎么使用BDAlog？
基础库不应该直接依赖BDALog，应该依赖BDALog的中间层 [BDAlogProtocol](https://code.byted.org/iOS_Library/BDAlogProtocol)

### 日志文件可在客户端解析吗？
每条log都会被加密压缩并且日志格式是完全自定义的，在客户端解析效率低成本高，如果是测试建议用Python脚本批量解析。


# 版本记录
0.3开头版本开始支持自定义公私钥加密方式，0.5开头版本优化了alog内部实现，强烈建议升级。
* v0.5.03 [优化] 调整public private头文件位置，避免内部实现和外部冲突
* v0.5.02 [修复] 修复12小时制设备下返回alog文件结果不准的问题
* v0.5.01 [修复] 1. 修复线上偶现assert失败崩溃问题，解决mmap写满时因无法添加尾部字符导致的数据失效的Bug 2. 优化内部errlog 3. flush时机优化，日志写入失败后仍可触发flush
* v0.5.00 [优化] 外部接口不变，优化alog内部实现，有效减少初始化耗时和解决部分卡死问题。详见: https://bytedance.feishu.cn/docs/doccnmpLvVw1L0O2aD8zbRmMbig#i99Dem
* v0.4.xx [废弃] 已被废弃
* v0.3.09 [修复] 修复控制台输出编码问题
* v0.3.08 [优化] 控制台输出改成NSLog
* v0.3.07 [优化] 修复ptrbuffer.cc 146的bug，即alog退出后异步写入可访问到已释放变量
* v0.3.06 [优化] 增加编译参数：禁止C++全局变量在进程退出后析构
* v0.3.05 [优化] 优化external callback中的多余的log format操作
* v0.3.04 [优化] 优化异步写入log的互斥锁范围，减少卡死问题
* v0.3.03 [修复] 修复自定义加密方式返回文件路径不准的问题
* v0.3.02 [修复] 修复自定义加密方式迁移过程中产生的兼容性问题，迁移测试报告见：https://bytedance.feishu.cn/docs/doccnD80iJ9Y0i34LpsN2zi0Qbd
* v0.3.01 [修复] 修复`log_detail_callback`接口未生效的问题
* v0.3.00 [废弃] 新增自定义公私钥加密方式，详情请见：https://bytedance.feishu.cn/docs/doccnerTgSVSdBcWnNCWfNoP4Oc
* v0.2.07 [优化] 1.优化异步写入log互斥锁范围 2.头文件内部收敛 3.新增OC包装的detail_log_callback接口
* v0.2.06 [修复] 1.修复alog文件路径获取不准的问题 2. 修复`log_detail_callback`接口未生效的问题 3. 增加编译参数：禁止C++全局变量在进程退出后析构
* v0.2.05 [废弃] 
* v0.2.04 [功能] 业务需求，新增`log_detail_callback`接口
* v0.2.03 [修复] 1.修复Debug模式下未默认输出log至控制台的bug 2. 应安全合规需求，将非注释部分的中文翻译成英文 3.修复AutoBuffer类中realloc失败后空指针的问题
* v0.2.02 [优化] 应TC安全合规需求，修正敏感词
* v0.2.01 [废弃] 应TC安全合规需求，修正敏感词
* v0.2.00 [优化] 优化包大小: `__FILE_NAME__` 替换 `__FILE__`
* v0.1.20 [修复] 修复size_t为unsigned long类型导致<0判断无效问题
* v0.1.19 [修复] 修复回捞文件时可能存在截取字符串越界导致的crash
* v0.1.18 [优化] 优化.alog文件命名策略，提升回捞成功率 
* v0.1.17 [修复] 修复[NSFileManager removeItemAtPath:error:]方法抛出异常没有处理可能导致crash的问题
* v0.1.16 [修复] 修复在主线程删除log文件可能导致crash的问题
* v0.1.15 [修复] tag黑名单不过滤error级别以上的log，fix 打开 warning as error后编译报错
* v0.1.14 [废弃] 回退至0.1.12
* v0.1.13 [废弃] 已被废弃
* v0.1.12 修复有些场景下Alog文件名不规范导致回捞失败的问题
* v0.1.11 提供可自定义line、filename和function宏
* v0.1.10 修复字符串越界导致crash
* v0.1.9 修复恶意循环写入大量log导致内存上涨问题
* v0.1.8 支持tag黑名单




