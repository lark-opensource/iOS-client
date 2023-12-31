# Heimdallr
## 简介 & 特性
Slardar 平台是字节跳动移动基础技术团队搭建的性能和体验保障平台，该平台具有异常监控、单点问题定位、基础性能指标监控分析、网络监控、图片监控、自定义事件打点报表分析、云控下发、报警等功能。

Heimdallr 是 Slardar 对应的客户端性能监控框架，[点击查看该库模块划分和对应功能](https://slardar.bytedance.net/help/iOS/)

## 版本要求
* iOS 8.0+
* Xcode版本：9.0+

## Example工程

* clone 工程
* 切换到Example目录
* pod install

## 接入方式 & 使用文档
CocoaPods接入方式支持：

* 源码支持
* 二进制支持

Swift支持：

* 支持，但是可能存在一些 bad case，望业务方充分测试


[更多细节，可以点击查看接入方式 & 使用文档](https://slardar.bytedance.net/help/iOS/integrate_ios.html)

## 需求 & Bug

[可以在 gitlab 给我们提 issue](https://code.byted.org/iOS_Library/Heimdallr/issues)

## 组件交流反馈群

[点击加入Lark反馈群](lark://client/chatchatId=6576195118598996237)

## 作者

排名不分先后

* fengyadong@bytedance.com
* xiejunyi@bytedance.com
* liushibin@bytedance.com
* wangjiale.joy@bytedance.com

## 更新记录
* v0.0.1 初始版本
* v0.0.2 修复OOM可能抓取不准的问题
* v0.0.3 修复偶现的主线程卡死的问题
* v0.0.4 修复APM一期稳定性和偶现内存暴涨的问题
* v0.0.5 修复一个代码顺序导致的稳定性问题
* v0.1.0 修复APM二期Feature:内存，cpu,流量，电量等性能指标自动采集和分析；支持指定用户的定向回捞
* v0.2.0 数据库实现重构，存储方案支持WCDB和FMDB可选，修复偶现的死锁和崩溃问题
* v0.3.0 SDK集成APM支持，修复部分数据本地聚合问题，修复页面跳转偶现的崩溃问题，修复WCDB封装查询语句问题
* v0.3.1 修复Swift工程中UI行为交互发生的崩溃问题
* v0.3.2 修复偶现的cpu占用过高和一个打包的问题
* v0.3.3 所有+load方法改造，修复UI交互跟踪埋点持久化占用主线程，修复同时开启卡顿和崩溃监控可能导致崩溃时卡顿的问题
* v0.3.4 修复multipart/form-data方式接口上报获取上行流量可能死循环 && Hook UICollectionView delegate之后可能为空的问题
* v0.3.5 willTerminate的时候停止监控&控制一个update操作的频率
* v0.3.6 解决和KSCrash库的文件名和符号冲突
* v0.3.7 修复enbale_net_stats与TTMonitor解析规则不一致的问题&规范package_name字段名
* v0.3.8 修复CrashTracker模块可能会重复初始化的问题
* v0.3.9 尝试修复内存dump崩溃的问题&修复启动时长可能存在超大数的问题&修复iOS8UITableView delegate释放会崩溃的问题
* v0.3.10 暂时下掉内存dump&OOM检测&安全气垫&Zombie等还没有充分验证的feature;Crash和异常debug模式下不报;修复iOS8获取app占用内存时候不准出现超大数的问题;crash时候停止性能指标的数据库写入;尝试修复一个FMDB查询和一个方法查找不到的Crash
* v0.3.11 暂时下掉UIScrollView hook方案&处理与 Aspects hook 冲突的问题&一些数据库事务挪到子线程&修复iOS8下SQLite一个语法报错的问题&暴露开启能力接口
* v0.3.12 修复HMDTTMonitor模块一个属性用错的bug
* v0.3.13 修改podspec中对FMDB版本号的限制
* v0.3.14 尝试修复网络监控偶现Crash的问题
* v0.3.15 修复数据库删除语句失败导致的数据上报重复和内存暴涨的问题
* v0.3.16 修复podspec中FMDB依赖指定版本的语法问题
* v0.3.17 打包脚本可以选择不执行
* v0.3.18 修复iOS8上因观察者未移除对象销毁后收到通知Crash的问题&修复sqlite update语法报错问题
* v0.3.19 修复一个内存泄漏和viewDidAppear与viewWillAppear参数传递不正确的问题
* v0.3.20 业务埋点无法被序列化增加断言&修改文件上报之后的文件名
* v0.3.21 修复一个判断数组非空的条件手抖漏写了count方法
* v0.3.22 锁定WCDB依赖版本
* v0.3.23 dsym上报脚本更新&磁盘监控模块进后台通知监听改到start方法而不是init方法
* v0.3.24 修复page_load数据偶现上报重复的问题&性能数据上报增加条数限制防止内存暴涨
* v0.4.0  upload，session，config等模块拆分适配SDK集成APM需求
* v0.4.1  修复两处内存泄漏的问题
* v0.4.2  修复TTNet Host可能获取不准确的问题
* v0.4.3  修复WCDB update时候可能存在野指针访问的问题
* v0.4.4  支持Alog日志文件回捞
* v0.4.5  修改Alog回捞文件名格式
* v0.4.6  修复一个主端编译问题
* v0.4.7  增加用户反馈时自动上报日志文件接口
* v0.4.8  monitor/collect接口上报默认加密
* v0.4.9  满足保密项目定制上报域名和隐藏敏感字符串的需求
* v0.4.10 规范网络监控的上报字段名，修复一个异常上报中变量未初始化的问题
* v0.4.11 上报header增加uid&修复一个内存单位不统一的问题
* v0.4.12 修复一个多线程环境下偶现的crash&修复APM SDK捕获Mach Exception类型的Crash与Fabric冲突的问题
* v0.4.13 废弃
* v0.4.14 修复因为加锁解锁不匹配导致线程阻塞数据上报异常的问题&取消WCDB版本号限制
* v0.4.15 新增接口业务方可以在崩溃的时候携带自定义的环境变量;当网络监控发现明确错误的时候，将错误的状态码从http
的状态码更新为NSError的errCode
* v0.4.16 修复头条放量过程中发现的多线程环境下偶现Crash的问题
* v0.4.17 废弃
* v0.4.18 支持业务方自定义Crash筛选条件的需求
* v0.4.19 支持业务方注册Crash之后的回调，支持Crash之后上报当次的Alog，修复头条灰度放量过程中遇到的偶现crash
* v0.4.20 修复头条内测中遇到的几个网络监控的问题，增加clientType字段标记当前网络库内核
* v0.4.21 修复重构后导致网络监控数据未被上报的问题
* v0.4.22 修复首次启动可能因为缓存openUDID卡死的问题&修复兼容logType配置中删除字段可能不生效的问题&废弃WCDB支持
* v0.4.23 支持sdk独立拉取配置和上报性能埋点
* v0.5.0 废弃对WCDB的支持，请之前用WCDB的各业务方迁移至FMDB;增加云控功能
* v0.6.0 增加OOM检测功能
* v0.6.1 增加OOM检测一个偶现的crash
* v0.6.2 属性关键字适配MRC
* v0.6.3 修复因为返回数据结构改变造成上报数据未清理问题
* v0.6.4 修复logType字段删除可能不生效的问题
* v0.6.5 增加dart异常上报能力
* v0.6.6 修复切换到后台后OOM监控可能引发的一个偶现Crash
* v0.6.7 去掉一个不必要的断言;优化了采集，上报和清理策略，避免极端case下引发的内存占用和磁盘占用异常的问题;在SDK内部一些关键节点加入了埋点监控，方便监控SDK本身的质量和定位问题
* v0.6.8 修复App启动10s发生的crash内存和磁盘占用等环境变量丢失的问题&优化App磁盘占用获取实现&修复性能指标定时器上报触发失效的问题
身的质量和定位问题
* v0.6.9 支持App打包时主工程commitid写入slardar平台的异常日志中，方便后续将问题分配给指定的研发
* v0.6.10 彻底清理WCDB文件&修复OOM检测时偶现的崩溃问题&HMDTTMonitor上报性能埋点通用字段与TTMonitor保持一致
* v0.6.11 修复Lite新版放量过程中遇到的几个稳定性问题，0.6.8-0.6.10版本均有该问题，请使用这几个版本的业务方尽快升级
* v0.6.12 电量监控忽略充电状态，增加每分钟电量消耗/每次使用周期电量消耗两个新指标;sdk独立监控配置和上报域名支持定制;修复KVO移除观察者和数据库多线程操作引发的偶现crash
* v0.6.13 修复Swift工程ui_action模块因为UIGestureRecognizer的target未继承自NSObject引起的crash;修复一些场景下ALog回捞可能不实时的问题;补充一个Unix Signal类型Crash捕获模块一个未定义的宏
* v0.6.14 优化sdk启动耗时，测试sdk整体启动耗时从50ms+=>10ms;增加最新设备名称;支持arm64e(目前主要是XsMax机型)架构的crash符号化
* v0.6.15 sdk拉取配置接口增加sdk版本号参数，方便业务方区分版本号下发不同的配置，[sdk版本号定义规则](https://docs.bytedance.net/doc/QXMgIjTeei8TuOE8uzUs3b);优化部分ALog日志格式
* v0.6.16 调整部分文件目录结构;业务层主动取消接口调用支持不记录在网络监控中;修复OOM检测偶现crash的问题;ui\_action模块在iOS8系统上不开启;修复api\_error日志类型不上报的问题
* v0.6.17 ALog主动上报增加上报结果的回调&监控原生网络请求从每次都新创建一个NSURLSession的实例修改为复用一个单例,提升性能
* v0.6.18 修复SDK独立依赖的时候一个编译的问题
* v0.6.19 修复一些场景下性能埋点可能被漏报的问题
* v0.6.20 fps监控支持区分是否时滑动的场景&提高Alog上报成功率&支持开关控制是否采集网络response
* v0.6.21 修复退后台之后fps计算可能不准的问题
* v0.6.22 规范上报设备名&上传dsym脚本支持上报到国际化机房
* v0.6.23 修复OOM模块因为MRC编译导致的一个内存泄漏问题&解档归档增加try catch保护逻辑&增加VC生命周期方法总耗时指标&切换写入工程commitID脚本至本地
* v0.6.24 Alog主动上报支持增加环境变量和触发上报的场景
* v0.6.25 卡顿上报增加页面信息和业务自定义环境变量&修复原生网络监控多线程环境偶现的crash&修复多线程环境创建dispatch_source_t类型的定时器偶现的crash
* v0.6.26 优化Crash log现场信息写入策略，修复上报的crash log偶现版本号信息是0的问题
* v0.6.27 TTNetHelper类计算http Header流量增加保护&修复原生网络监控回调线程与入口线程不一致导致的偶现crash&修复磁盘监控判断阈值时的一个单位错误&crash log版本号增加兜底策略，如果环境文件中读不到版本号，则从crash log中读出来
* v0.6.28 修复脚本中处理空格问题
* v0.6.29 已废弃
* v0.6.30 SDK内部所有网络接口优先使用TTNet内核&增加上下行移动/wifi测速功能&修复连续多次触发alog上报可能造成的重复上报问题&主动上报alog前flush异步改为同步&性能监控支持在特定页面中自定义tag
* v0.6.31 支持小程序性能数据筛选&卡顿OOM大内存检测等性能有损的模块未命中上报开关则本地不开启&新性能埋点接口兜底，防止传入可变集合类线程不安全导致的稳定性问题&更新数据库记录偶现的稳定性问题增加保护
* v0.6.32 修复一个编译问题
* v0.6.33 dsym上传脚本支持传入地区和aid两个参数
* v0.6.34 拆分云控拉取配置接口，优化请求发起的策略&废弃旧的文件上报接口
* v0.6.35 下掉一个废弃的文件回捞feature，统一接入云控
* v0.7.0 更新说明:
	1. SDK子库和配置模块重构，修改之后代码子模块更加独立，代码更清晰，更容易维护
	2. 消灭SDK内部所有预编译宏，为收敛打包分支做准备，支持静态库集成
	3. 优化OOMDetector性能问题，优化后最大性能损耗不超过10%
	4. 新增异常磁盘，异常文件夹和过期文件功能，方便业务方定位磁盘问题
	5. 重构crash抓取模块，crash log日志文件写入api从OC统一改为c方法
	6. 优化卡顿监控的准确性
* v0.7.1 更新说明:新增OOM崩溃检测能力
* v0.7.2 更新说明:解决VideoEditor SDK独立编译问题
* v0.7.3 更新说明:
	1. 新增wacth dog卡死检测能力，开启此模块之后OOM崩溃的判定会更准确，集成文档见：[watch dog集成文档](https://slardar.bytedance.net/docs/115/165/2399/#%E5%A6%82%E4%BD%95%E9%9B%86%E6%88%90-4)
	2. 新增自定义异常埋点和上报，聚合能力，集成文档见：[自定义异常集成文档](https://slardar.bytedance.net/docs/115/165/2399/#%E5%A6%82%E4%BD%95%E9%9B%86%E6%88%90-5)
	3. 崩溃时内存和磁盘占用等现场信息写入方式改为safe api，避免crash抓取时二次崩溃的问题
	4. 重构获取Heimdallr内部模块开启状态的api，解决老接口调用时有概率卡死的问题，新的api和用法见Heimdallr+ModuleCallback.h声明
* v0.7.4 已废弃
* v0.7.5 更新说明:
	1. Heimdallr新增磁盘清理模块，默认db文件磁盘占用阈值50MB，支持配置 [配置方式](https://slardar.bytedance.net/docs/115/165/2395/#sdk%E7%A3%81%E7%9B%98%E5%8D%A0%E7%94%A8%E6%B8%85%E7%90%86%E7%AD%96%E7%95%A5)
	2. 支持BackgroundSession方式上传Crashlog，提高上报及时性和成功率[配置方式](https://slardar.bytedance.net/docs/115/165/2399/#%E5%A6%82%E4%BD%95%E5%BC%80%E5%90%AFbackgroundsession%E6%A8%A1%E5%BC%8F%E4%B8%8A%E6%8A%A5crash-log)
	3. 卡顿监控详情页支持展示卡顿时长
	4. 废弃FMDB子库，与HMDStore子库合并，保证所有子库均可独立编译
	5. 原生网络监控的子库从`HTTPRequestTracker`改为`HMDURLProtocolTracker`，保证HMDURLProtocol拦截的优先级最低，规避潜在的和其他业务拦截器冲突的风险
	6. 安全气垫模块灰度发布，集成文档见：[安全气垫集成文档](https://slardar.bytedance.net/docs/115/165/2399/#%E5%AE%89%E5%85%A8%E6%B0%94%E5%9E%AB)，有需求请联系孙润望对接
* v0.7.6 更新说明:
	1. 新增SDK Log分析Crash在捕获和上报时的潜在问题
	2. 修复Crash抓取时因为有锁api或者堆上分配内存导致的卡死和二次崩溃的问题，与上个版本相比与fabric gap从7%降低至1.4%
	3. 修复用户因为遇到卡顿失去耐心后强制退出App下次启动时被误判为OOM的问题
	4. 强制checkpoint解决wal文件可能体积过大的问题（需要依赖FMDB升级至2.7.5版本）
* v0.7.7 更新说明:
	1. 支持更加精准的调用栈回溯方式，[如何开启](https://doc.bytedance.net/docs/115/165/2399/#%E5%A6%82%E4%BD%95%E5%BC%80%E5%90%AF%E6%96%B0%E7%9A%84%E8%B0%83%E7%94%A8%E6%A0%88%E5%9B%9E%E6%BA%AF%E6%96%B9%E5%BC%8F)
	2. 继续优化Crash模块抓取卡死和二次崩溃的问题
	3. 后端支持Crash/卡死/卡顿模块重复日志上报的过滤
	4. 修复HMDTTMonitor模块偶现用户日志丢失的问题
	5. 解决sdk monitor误拼接宿主通用参数的问题
	6. 优化数据库清理策略，解决数据库清理后文件体积不符合预期的问题
	7. 修复卡顿监控模块一个内存泄漏的问题
	8. 修复用户升级后老版本wacthdog/卡顿/OOM等异常日志上报误判为新版本的问题
* v0.7.8 更新说明:
	1. 修复sdk monitor host_aid参数错误的问题
	2. 符号表上传脚本更完美的兼容New Build Syetem编译系统
	3. 修复安全气垫模块可能存在的内存泄露
* v0.7.9 更新说明:
	1. 完成Crash抓取模块整体重构，支持开关和逐步放量，开启后可以提升抓取成功率和栈回溯的准确性
	2. 网络请求支持Header中注入CND采样标识
	3. 支持crash/网络监控等各个模块在新用户首次安装时候默认开启
	4. 修复HMDFinderVC模块开启后presentationViewController引起的循环引用
	5. 修复双卡设备用户运营商信息可能读取不准确的问题
	6. 云控指令轮询接口优先用TTNet网络库发起
	7. 卡顿事件增加是否发生在启动阶段的标志
	8. 修复安全气垫功能在部分系统版本下的兼容性问题
* v0.7.10 更新说明:
	1. 卡死卡顿模块重构，提高调用栈抓取的准确性
	2. 云控接口优先TTNet发起
	3. 修复崩溃/卡顿模块获取线程名偶现crash的问题
	4. 修改用户多sim卡时运营商信息获取不准的问题
	5. Heimdallr BDAlog日志精简
* v0.7.11 更新说明:
	1. 加密库升级适配
	2. 支持在崩溃/卡死卡顿/OOM详情页中查看用户最近进入的页面轨迹
	3. 提高OOM崩溃监控的准确性，降低误报
	4. 云控支持删除沙盒任意路径下的内置指令
	5. 修复卡死/卡顿重构后可能导致误报的问题
	6. 优化Heimdallr的磁盘占用
	7. 优化db vacuum时机，避免超大db文件vacuum时可能导致的OOM问题
* v0.7.12 更新说明:
	1. 修复静态代码扫描检查出的若干代码规范性问题
	2. 支持崩溃时的异步调用栈抓取
	3. 安全气垫支持更多保护能力
	4. 降低OOMDeector误报的概率
* v0.7.13 更新说明:
	1. 旧版图片监控下线
	2. 旧版Crash抓取下线
	3. C++崩溃调用栈抓取更精准
	4. device_model下线本地映射策略，新增一个设备性能等级的参数
	5. 事件上报支持指定单次上报流量阈值
* v0.7.14 更新说明:
	1. watchdog监控模块使用C/C++重构，避免因为OC runtime死锁导致调用栈抓取失败的问题
	2. watchdog放开50条最大线程限制
	3. watchdog新增卡死前主线程多次调用栈抓取的能力
	4. NSUserDefaults替换为HMDUserDefaults，规避崩溃或者卡死的问题
	5. 后台启动忽略启动监控，规避因为后台挂起导致启动时间异常的问题
	6. 支持dwarf类型的栈回溯，调用栈回溯更精确
	7. 越狱检测优化
	8. 支持所有功能模块全开，所有事件采样率100%命中的线下模式
* v0.7.15 更新说明:
	1.  【异常】【新增】新增OOM崩溃排查利器-Slardar MemoryGraph，接入文档：https://slardar.bytedance.net/docs/115/165/41057/
	2.  【平台】【新增】新增客户端全链路监控Slardar OpenTracing模块，接入文档：https://slardar.bytedance.net/docs/115/165/40837/
	3.  【平台】【新增】新增基于Slardar OpenTracing模块的启动Trace功能，接入文档：https://slardar.bytedance.net/docs/115/165/41302/
	4.  【异常】【新增】新增灰度可用的zombie检测模块，功能介绍：https://bytedance.feishu.cn/docs/doccnHLpTXbZ7An9rmfv8KMkemg
	5.  【异常】【新增】新增App重启原因的接口暴露
	6.  【性能】【优化】优化App内存占用和可用内存指标的准确性
	7.  【异常】【优化】自定义异常提供异步日志生成接口，解决同步生成日志卡死性能问题
	8.  【异常】【优化】安全气垫支持重复crash防护的过滤
	9.	【异常】【优化】安全气垫模块支持排除try catch误报
	10. 【性能】【优化】优化UITracker模块 isClassFromApp方法的耗时
	11. 【异常】【修复】修复OOM崩溃模块在App快速前后台切换时可能导致误判的问题
	12. 【性能】【修复】网络白名单for循环增加autoreleasepool，解决正则表达式NSRegularExpression可能在for循环中累积过多导致的OOM问题
	13. 【性能】【修复】将电量监控的启动放到主线程，避免iOS11以下系统可能存在的系统api线程不安全导致的崩溃
* v0.7.16 更新说明:
	1.已废弃，请使用0.7.17版本
* v0.7.17 更新说明:
	***注意：出于国内外数据隔离的要求，Heimdallr国内和海外域名拆分为两个子库，App方必须在接入的时候手动指定HMDDomestic或者HMDOverseas子库*
	1.  【异常】【新增】新增卡死保护模块，接入文档：https://slardar.bytedance.net/docs/115/165/2399/#watchdog%E4%BF%9D%E6%8A%A4
	2.  【异常】【新增】新增UI冻屏监控模块，接入文档：https://slardar.bytedance.net/docs/115/165/2399/#ui%E5%86%BB%E5%B1%8F%E7%9B%91%E6%8E%A7
	3.  【性能】【优化】磁盘监控SDK改造支持一二级目录占比监控，目录变化趋势等需求，产品文档：https://bytedance.feishu.cn/docs/doccnAnZ4LwVsE13mvbelUdThvb
	4.  【异常】【异常】安全气垫彻底排除部分场景下try catch误报
	5.  【异常】【修复】排除App被WDA框架测试时OOM的误判
	6.  【事件】【优化】解决Heimdallr未拉到配置之前事件埋点无法命中采样率的问题
	7.  【云控】【修复】修复Alog云控回捞偶现报错的问题
	8.  【基础】【优化】优化db encode性能
	9.  【异常】【新增】crash模块支持提取崩溃时容器类对象信息
	10. 【性能】【优化】优化Heimdallr初始化耗时
	11. 【基础】【修复】保证alogflush，上传，删除文件的原子性，修复偶现的重复上报的问题
* v0.7.18 更新说明:
	1.  【性能】【新增】fps丢帧监控新增数据回调
	2.  【事件】【修复】修复部分极端场景下因为用户手动修改时间或者锁屏等操作导致耗时计算不准确的问题，修复因为断点导致断言被错误触发的问题
	3.  【性能】【新增】CPU 暴露方法获取 CPU使用情况
	4.  【基础】【修复】修复极端情况下因为配置域名下发错误导致配置获取接口一直获取失败的问题
	5.  【异常】【修复】修复安全气垫Container Hook方法存在尾调用，造成线程堆栈不明确的问题
	6.  【基础】【优化】URLSettings 增加同时存在国内外域名子库的断言
	7.  【基础】【优化】上报接口默认加密
	8.  【基础】【修复】修复偶现的gcd timer造成的卡死
	9.  【异常】【优化】OOM崩溃排除自动化测试环境下的误判
	10. 【基础】【优化】优化Heimdallr初始化耗时
	11. 【基础】【修复】配置接口拉取的时候error为空但是状态码出错的情况下也触发重试
* v0.7.19 更新说明:
	1.  【事件】【新增】事件监控添加埋点用于计算漏报率和采样偏移率
	2.  【性能】【移除】TTMLeaksFinder相关子库和代码剥离
	3.  【异常】【新增】安全气垫新增云端防护任意OC方法的能力（需依赖Stinger）
	4.  【事件】【优化】添加计时器，30s定时将内存中的数据写入数据库，降低事件埋点丢失的概率
	5.  【异常】【优化】UI冻屏检测判定逻辑修改为相同实例view连续多次无响应，并支持切后台通知
	6.  【异常】【修复】修复安全气垫Container Hook方法存在尾调用，造成线程堆栈不明确的问题
	7.  【基础】【修复】修复Heimdallr内部的GCD Timer偶现的卡死问题
	8.  【基础】【修复】完成Heimdallr安全合规改造，修复了包括敏感词，日志中出现中文，国内域名硬编码，加密算法不标准，密钥预置在本地等各种有风险的问题
	9.  【性能】【新增】新增类级别和行级别代码覆盖率检测
	10. 【基础】【修复】将GCDTimer改成多实例，修复因为多实例的timer名字相同导致的线程安全问题
	11. 【事件】【修复】修复SDKMonitor模块存在的两处循环引用的问题
	12. 【异常】【修复】修复因为DWARF_DSYM_FOLDER_PATH和BUILT_PRODUCTS_DIR不一致导致的符号表上传脚本报错的问题
	13. 【性能】【修复】修复网络监控模块启动时存在的重复hook导致的递归调用crash风险的问题
	14. 【异常】【新增】新增向SDK暴露卡顿耗时监控的能力
	15. 【基础】【修复】修改Heimdallr本身被依赖时的编译选项，不注册c++全局变量的析构函数，规避应用退出时可能出现的崩溃问题
	16. 【异常】【修复】修复BootingProtection模块存在的上次进程终止原因可能不准确的问题
	17. 【基础】【修复】修复Heimdallr内部封装的hmd_safe_dispatch_async方法传入的queue为nil时会crash的问题
* v0.7.20 更新说明:
	1.  【基础】【优化】Heimdallr SDK头文件收敛
	2.  【异常】【新增】安全气垫新增NanoCrash和Qos Over Commit两种系统崩溃保护
	3.  【性能】【新增】FPS FrameDrop 支持高帧率
	4.  【基础】【新增】支持Swift代码直接调用的BDAlogWrapper
	5.  【异常】【新增】安全气垫增加对NSNumber、NSSet、NSMutableSet的支持
	6.  【异常】【修复】修复安全气垫Container Hook方法存在尾调用，造成线程堆栈不明确的问题
	7.  【基础】【修复】安全合规将流量监控单独拆分出来，从0.7.20-rc.11版本开始将流量监控功能拆分成子库 NetworkTraffic, 如果业务中需要流量监控的相关功能的话需要在 Heimdallr subspecs 添加  NetworkTraffic 子库, 如果不需要流量相关的功能则不需要额外的操作
	8.  【异常】【新增】白名单上的自定义异常不限流
	9.  【性能】【新增】新增获取GPU使用率的子库
	10. 【异常】【修复】修复cpu_subtype未处理掩码的问题
	11. 【基础】【优化】增加userID/installID/deviceID的动态注入方式
	12. 【基础】【优化】完成中文改造
	13. 【异常】【新增】dart异常上报支持同步上传Alog
* v0.7.21 更新说明:
	1.  【性能】【新增】支持异常CPU占用的监控，接入文档：https://bytedance.feishu.cn/docs/doccnLUlqcjVjrwScQ7xrvy6nSd
	2.	【事件】【修复】修复事件埋点模块启动时小概率卡死的问题
	3.	【云控】【优化】Alog端文件上报提升云控回捞Alog的成功率
	4.	【性能】【优化】网络监控api_error日志忽略2XX状态码
	5.	【异常】【修复】修复安全气垫KVO在iOS 11.2系统有可能崩溃的bug
	6.	【性能】【新增】支持启动函数级别的耗时分析
	7.	【优化】【云控】文件上报加密key字段ran获取不区分大小写
	8.	【事件】【优化】启动trace忽略未结束的assert
* v0.7.22 更新说明:
	1.  【事件】【优化】SDKMonitor重构，彻底解除对后端压力的隐患
	2.	【基础】【新增】新增Heimdallr内部磁盘清理策略，保证crash卡死等模块的文件写入空间
	3.	【异常】【优化】在子线程强行退出app，仍然记录卡死日志
	4.	【云控】【新增】添加数据清理云控命令
	5.	【云控】【优化】将alog not found视为成功；修改回捞alog的文件名显示
	6.	【性能】【优化】启动分析忽略后台启动场景
	7.	【异常】【修复】修复因为__TEXT段迁移导致大内存分配调用栈解析错误的问题
	8.	【性能】【修复】修复CPU异常监控因为JSON调用树层级过深引起的crash
	9.	【异常】【新增】自定义异常支持传入需要被符号化的地址
* v0.7.23 更新说明:
	1.	【基础】【优化】事件埋点上报接口支持容灾
	2.	【性能】【新增】新增异常流量消耗监控能力，接入文档：https://bytedance.feishu.cn/wiki/wikcnR0j425amod5QlKfrLl73Vg
	3.	【云控】【优化】优化云控回捞的成功率，成功率57%=>80%
	4.	【性能】【优化】因安全合规原因下掉智能流量监控功能模块
	5.	【基础】【修复】修复因data_const无写权限导致fishhook crash的问题，适配iOS14.5
	6.	【异常】【新增】新增内存踩踏类疑难问题的排查工具CoreDump，接入文档：https://bytedance.feishu.cn/docs/doccnsgUJtYIBk8up9K9LHuYZYd
	7.	【事件】【修复】支持C++层与OC层打通的全链路监控接口
	8.	【异常】【修复】修复自定义异常埋点太频繁且在debug环境下本地符号化导致的CPU占用过高的问题
* v0.7.24 更新说明:
	1.	【性能】【优化】磁盘监控支持监控多级目录和更灵活的配置
	2.	【异常】【优化】UI冻屏监控完全适配DY
	3.	【异常】【修复】修复64位设备上TaggedPointer Unrecognized Selector Crash没有兜住的问题
	4.	【异常】【优化】降低崩溃调用栈抓取失败导致异常调用栈为空的概率
	5.	【异常】【修复】修复zombie监控偶现的崩溃和卡死问题
	6.	【异常】【优化】zombie模块支持通过配置类名，来捕获部分对象调用dealloc函数
	7.	【异常】【修复】修复M1 Mac上App必现误判为越狱的问题
* v0.7.24 更新说明:
	1.	【性能】【优化】磁盘监控支持监控多级目录和更灵活的配置
	2.	【异常】【优化】UI冻屏监控完全适配DY
	3.	【异常】【修复】修复64位设备上TaggedPointer Unrecognized Selector Crash没有兜住的问题
	4.	【异常】【优化】降低崩溃调用栈抓取失败导致异常调用栈为空的概率
	5.	【异常】【修复】修复zombie监控偶现的崩溃和卡死问题
	6.	【异常】【优化】zombie模块支持通过配置类名，来捕获部分对象调用dealloc函数
	7.	【异常】【修复】修复M1 Mac上App必现误判为越狱的问题
* v0.7.25 更新说明:
> 升级适配指南:https://bytedance.feishu.cn/wiki/wikcnShW50nVSyRoB7q1doLjDPh
	1.	【基础】【优化】Heimdallr 所有subspec头文件收敛
	2.	【基础】【优化】配置接口settingv4 改造，节约服务器资源
	3.	【异常】【优化】安全气垫新增5个常见方法的防护，解决iOS15上的误报问题
	4.	【事件】【优化】优化事件重复上报：只要删除失败就暂停上报
	5.	【基础】【优化】适配 1.x stinger API ，升级stinger版本 ，AWECloudCommand版本
	6.	【异常】【优化】优化thread null问题：减少老设备和主线程退出时候产生的Crash不能正常写入问题
	7.	【异常】【优化】优化Memorygraph极端条件下磁盘占用过大问题
	8.	【异常】【优化】减少segment读取时候，crash模块频繁的堆内存操作
	9.	【性能】【修复】修复 cdn trace-log 的 enable_base_api_all 采样率无法生效的问题
	10.	【性能】【优化】磁盘和内存合规改造，改为区间值而不是精确值
	11.	【事件】【优化】优化NSLog和printf重定向到Alog的技术实现
	12.	【异常】【优化】fishhook完全适配14.5系统
	13.	【异常】【优化】MetricKit应用退出原因归因上线
* v0.7.26 更新说明:
> 升级适配指南:https://bytedance.feishu.cn/wiki/wikcnLBi9jfx6dkDPAGU5w2GLaf
	1.	【基础】【新增】Heimdallr支持TTNet染色流量管控
	2.	【异常】【新增】[NSMutableString appendString:]方法的安全气垫防护
	3.	【基础】【优化】HMDFileUploader文件上报接口改动
* v0.7.27 更新说明:
> 升级适配指南:https://bytedance.feishu.cn/wiki/wikcnpExtXlKCUEucbeO0RRn1Ze
	1.	【基础】【新增】新增对于M1设备的识别
	2.	【异常】【新增】UIFrezon新增独立页面消费
	3.	【异常】【优化】安全气垫-[NSString replaceCharactersInRange:withString:]等方法的防护
	4.	【异常】【新增】新增慢函数模块，可监控到主线程的慢函数执行，支持C/C++/OC/Swift
	5.	【性能】【新增】新增丢帧监控静止时支持采样回调
	6.	【性能】【新增】流量监控模块新增callback业务流量使用
	7.	【基础】【修复】修复配置模块一处多线程同时读写可能导致偶现的crash
	8.	【异常】【优化】MetricKit二期兼容段迁移
	9.	【基础】【优化】创建文件夹改为c方法创建，优化Heimdallr启动耗时
	10.	【基础】【优化】如果device_id等参数为空的话，使用"0"作为兜底的默认值
	11.	【异常】【新增】异常模块支持视图栈层级的捕获及上报
	12.	【异常】【新增】新增修复字节全系产品top crash libdispatch问题的安全气垫防护
	13.	【异常】【新增】MemoryGraph模块增加vm：stack结点关联线程名或队列名
	14.	【事件】【新增】BDAlog支持NSLog重定向注入回调 
* v0.7.28 更新说明:
> 升级适配指南:https://bytedance.feishu.cn/docs/doccne9TTioDPzZXyR6W7mnv0Fb#
	1.	【性能】【优化】CPU异常监控异常堆栈调用树的聚合改为服务端聚合
	2.	【异常】【修复】修复App第一次启动还没退后台就OOM崩溃监控不到的问题
	3.	【事件】【优化】基于管道优化NSLog/Printf重定向至alog的实现
	4.	【性能】【优化】磁盘获取异常TOPN逻辑算法改为堆排序
	5.	【性能】【优化】优化MemoryGraph发送内存警告机制，单次超过阈值80%只发送一次警告、适配ios11多线程执行HMD_HOST_STATISTICS可能导致卡死的问题
	6.	【异常】【新增】-[NSArray subarrayWithRange:]方法新增安全气垫防护
	7.	【异常】【优化】hmd_async_image_t的创建从堆中改为栈中，修复一个偶现的内存异常问题
	8.	【异常】【优化】安全气垫自定义防护不允许防护部分系统方法，防止递归调用
	9.	【性能】【新增】新增获取CPU当前最大频率的功能
	10.	【性能】【优化】优化了获取GPU使用率的耗时
	11.	【异常】【新增】新增文件描述符耗尽监控，当FD耗尽时会记录当前程序打开的文件，并记录相关信息进行上报
	12.	【异常】【优化】优化慢函数监控的自身性能损耗
	13.	【异常】【修复】修复Zombie监控偶现卡死卡顿的问题
	14.	【基础】【新增】Slardar 日志基础信息新增日志生产时的网络质量
	15.	【异常】【新增】新增任意OC方法卡死保护的能力
* v0.7.29 更新说明:
> 升级适配指南:https://bytedance.feishu.cn/wiki/wikcnAAkYEMmOacOlvhjBixginh
	1.	【基础】【优化】dladdr迁移至bundleForClass减少函数耗时
	2.	【异常】【优化】UI冻屏独立模块监控
	3.	【异常】【优化】oom监控模块增加scene和cpu的上报，memory_pressure增加有效时间的校验
	4.	【异常】【优化】新增-[NSMutableString appendString:]方法的安全气垫防护
	5.	【异常】【新增】-[NSArray subarrayWithRange:]方法新增安全气垫防护
	6.	【基础】【新增】所有网络请求支持自定义通用参数
	7.	【异常】【优化】zombie：优化性能，支持可配具体监控的类
	8.	【基础】【优化】OC方法替换为C方法，优化创建文件夹性能
	9.	【事件】【优化】devic_id为0或者不存在时数据上报延迟
	10.	【异常】【新增】卡死监控新增CPU占用参数
	11.	【异常】【优化】支持可配置ttnet上传crash
	12.	【异常】【修复】修复可能造成machport泄漏问题
	13.	【事件】【修复】修复Alog模块fd可能泄漏的bug+互斥锁重复初始化的Bug
	14.	【异常】【修复】解决安全气垫的捕获队列数据在遇到重复数据上报时的异常问题
* v0.8.0 更新说明:
> 升级适配指南:https://bytedance.feishu.cn/wiki/wikcnlOVgivkQQNpjzcmyeBzemh
	1.	【基础】【优化】拉取配置的接口返回的数据结构发生改变，具体格式变动：https://bytedance.feishu.cn/wiki/wikcnne0lpOEVrF7KYevZLCI5Mf
	2.	【性能】【优化】性能模块支持单独设置每个模块的采样
	3.	【异常】【优化】异常模块exception_modules，lag，oom，protector，user_exception支持设置日志上报采样
	4.	【云控】【优化】云控回捞内存日志和 线上MemoryGraph数据打通，需强制升级AWECloudCommand到>=1.3.3，否则会出现编译问题
	5.	【基础】【优化】修复了刚启动之后用户停留页面为"unknown"的问题
* v0.8.1 更新说明:
> 升级适配指南:https://bytedance.feishu.cn/wiki/wikcn69i6v0bx4soxAOHI0VhqEg
	1.	【异常】【新增】新增内存问题检测利器：GWPASan
	2.	【异常】【修复】修复MetricKit兼容策略在主线程调用栈超过100帧时，获取main地址异常的问题
	3.	【性能】【修复】修复网络监控记录response body过大导致的oom问题
	4.	【性能】【优化】为了后续对降级case做优化增加了对于降级case的数据统计，需要强制更新MemoryGraphCapture到1.3.5
	5.	【异常】【优化】自定义 Catch 防护、卡死保护支持即时关闭
	6.	【异常】【优化】自定义 Catch 防护、自定义卡死保护支持生效率稳定性监控、支持单点追查
	7.	【异常】【优化】安全气垫上报时将额外添加疑似 Jailbreak Image 的动态库信息，在原有安全气垫减少非符号化必要的 Image 上传逻辑外，可以对作弊用户进行判断
	8.	【异常】【修复】修复安全气垫在 iOS 当前线程过多导致的，对于主线程卡死保护可能无法生效的问题
	9.	【异常】【优化】修正安全气垫的USEL兜底逻辑，当无法进行USEL防护的情况下，不进行防护+走正常异常抛出逻辑
	10.	【异常】【新增】安全气垫新增对 NSAssert 防护逻辑，对于部分系统库包含的 NSAssert 断言和误将在Debug模式下编译的包发放到线上的情况进行防护上报
	11.	【异常】【优化】安全气垫对于 NSDictionary 字典类型的防护优化逻辑，只丢弃无效nil数据，剩余数据依然生存字典
* v0.8.2 更新说明:
> 升级适配指南:https://bytedance.feishu.cn/wiki/wikcnPzbbyanfEnMED4eBxaUKGb
	1.	【性能】【新增】新增SlardarMalloc，降低App进程内内存占用，降低OOM崩溃发生概率
	2.	【基础】【优化】Heimdallr各模块支持异常流量时自动容灾
	3.	【异常】【修复】修复GWPASan偶现的稳定性问题
	4.	【性能】【优化】启动监控适配iOS15 prewarm
	5.	【异常】【优化】统一SlardarMalloc和GWPASan的hook方式，避免偶现的稳定性问题
	6.	【事件】【优化】slardar tracing监控trace(span)未命中采样率时不落盘
	7.	【性能】【优化】升级memorygraph->1.3.6. 修复了某些c++对象无法识别的case，不需要业务方适配API