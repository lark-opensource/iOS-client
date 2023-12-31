# TTNetworkManager  

## 简介  

TTNetworkManager：字节跳动网络基础库，它为字节跳动的各个客户端提供了接入网络的API，以下简称TTNet。TTNet是一个基于[Chromium Network Stack](http://dev.chromium.org/developers/design-documents/network-stack)（Google Chromium的网络层内核），同时加入了比如[通用函数加密](https://wiki.bytedance.net/pages/viewpage.action?pageId=81842748)，[智能选路容灾](https://wiki.bytedance.net/pages/viewpage.action?pageId=100402429)，[DNS反劫持](https://wiki.bytedance.net/pages/viewpage.action?pageId=81833528)等功能（具体模块可以参见[网络库模块](https://wiki.bytedance.net/pages/viewpage.action?pageId=98349735)下的子目录），最后被抽象为几个接口提供给iOS以及Android两个客户端使用的一个通用网络库。在TTNet通用网络库实现之前，iOS客户端使用的AFNetworking，而Android使用的OKHttp端，为了使基础库通用同时加入我们自己想要的特性，我们开发出TTNet，本文档是iOS端网络库的相关说明。  

## 特性  

1. 提供统一的API接口，支持双内核切换，支持H2、QUIC等新协议  

2. 能获取各阶段详细的timing信息，可以用来排查网络瓶颈  

3. 支持HttpDNS，避免DNS劫持；支持动态下发哪些域名走HttpDNS，支持下发local DNS与HTTPDNS的解析顺序；支持下发hardcode ip列表以及保底ip

4. 具备动态选路功能，客户端根据策略动态选择CDN、ISP、BGP中的最优路线，支持下发不同线路域名，增加可用性。具体的选路过程见[IES选路下沉客户端设计与实现文档](https://wiki.bytedance.net/pages/viewpage.action?pageId=250283162)和[客户端智能选路V2](https://wiki.bytedance.net/pages/viewpage.action?pageId=70854739)  

5. 具备流控功能，支持scheme/host/path级别的细粒度控制替换，可以动态下发控制策略到端上，用于快速解决运营商劫持、服务商局部故障、端流量雪崩等问题，详细内容见[这里](https://wiki.bytedance.net/pages/viewpage.action?pageId=86869835)  

6. 具备拨测功能，支持在用户手机端进行get测试，并上报timing数据

7. 与公司统一监控平台对接，便于分析crash等类型数据的分析；另外Chromium内部也提供netlog记录着请求的详细信息

## 版本要求  

- iOS版本： 8.0+
- Xcode版本：9.0+
- TTNet版本：2.x.x.x

## Pod库地址

- 申请pod私有库权限  
  - source git@code.byted.org:TTIOS/tt_pods_network.git
  - 以tag的形式引入某版本（推荐方式）
    - pod 'TTNetworkManager', '2.2.8.73-rc.0'
  - 以commit的形式引入
    - pod 'TTNetworkManager', git:'git@code.byted.org:TTIOS/tt_pods_network.git', :commit => '71f54178ab42d9ecefd3d888f41ce1b21dbf3715'

## 运行Example工程  

- clone工程
- 切换到Example目录
- 执行pod install

## 接入方式

CocoaPods接入方式支持：支持**源码**和**二进制**  
  
Swift支持：需要使用**Modular Header**

## 初始化代码示例

- 网络库需要在appDidFinishLaunch 后尽快初始化以便后续网络请求快速发出。

- 1）设置监控回调（**必须要设置**） 这样C++内部产生的监控事件会通过这个回调最终通过TTMonitor发送出去。

```OC

Monitorblock block = ^(NSDictionary* data, NSString* logType) {
        LOGD(@"%s logType %@", __FUNCTION__, logType);
        [[TTMonitor shareManager] trackData:data logTypeStr:logType];
    };
[TTNetworkManager setMonitorBlock:block];

```

- 2）设置GetDomain 回调 （**可选**）。 TTNet C++模块会控制对get domain服务的请求， 如果业务也需要get domain的信息， 则可以注册这个回调， 这样每次C++层取得新的getdomain结果都会回调给应用层  

```OC
GetDomainblock GetDomainblock = ^(NSData* data) {
    NSError *jsonError = nil;
    LOGD(@"%s GetDomainblock is %@", __FUNCTION__, data);
    id jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

    if ([SSCommonLogic isRefactorGetDomainsEnabled]) {
        [[CommonURLSetting sharedInstance] refactorHandleResult:(NSDictionary *)jsonDict error:jsonError];
    } else {
        [[CommonURLSetting sharedInstance] handleResult_:(NSDictionary *)jsonDict error:jsonError];
    }
};
[TTNetworkManager setGetDomainBlock:GetDomainblock];
```

- 3）添加动态开关来控制网络库内核是AF还是Chrome（**必须设置，不设置默认是AF内核**）
```OC
BOOL isChromiumEnabled = [TTRouteSelectionServerConfig sharedTTRouteSelectionServerConfig].isChromiumEnabled;
if (isChromiumEnabled) {
    [TTNetworkManager setLibraryImpl:TTNetworkManagerImplTypeLibChromium];
} else {
    [TTNetworkManager setLibraryImpl:TTNetworkManagerImplTypeAFNetworking];
}
```

- 4）设置app通用参数回调 （**必须设置**）。 这些参数是C++层用来构造get domain请求所需的app通用参数。

```OC
[[TTNetworkManager shareInstance] setCommonParamsblock:^(void) {
    NSMutableDictionary *commonParams = [[NSMutableDictionary alloc] init];
    [commonParams addEntriesFromDictionary:[TTNetworkUtilities commonURLParameters]];
    if ([TTRouteSelectionServerConfig sharedTTRouteSelectionServerConfig].figerprintEnabled && !isEmptyString([TTFingerprintManager sharedInstance].fingerprint)){
        [commonParams setValue:[TTFingerprintManager sharedInstance].fingerprint forKey:@"fp"];
    }

    return [commonParams copy];
}];
```

- 5）设置get-domain域名（**必须设置**）
```OC
[TTNetworkManager shareInstance].ServerConfigHostFirst = @"dm.tnc.test.com";
[TTNetworkManager shareInstance].ServerConfigHostSecond = @"dm.bytedance.com";
[TTNetworkManager shareInstance].ServerConfigHostThird = @"dm-hl.tnc.test.com";
[[TTNetworkManager shareInstance] setDomainHttpDns:@"dig.bdurl.net"];
[[TTNetworkManager shareInstance] setDomainNetlog:@"crash.snssdk.com"];
```

- 6）配置反作弊库，设置反作弊库回调 （**可选**）

```OC
IESAntiSpamConfig *config = [IESAntiSpamConfig configWithAppID:@"123" spname:@"app_name" secretKey:@"2a35c29661d45a80fdf0e73ba5015be19f919081b023e952c7928006fa7a11b3"];
[IESAntiSpam setSessionBlock:^NSString * {
    NSString *sessionId = [[TTInstallIDManager sharedInstance] deviceID];
    return sessionId;
}];
[[IESAntiSpam sharedInstance] startWithConfig:config];
TTURLHashBlock hash = ^(NSURL *url, NSDictionary *formData) {
    return [[IESAntiSpam sharedInstance] encryptURLWithURL:url formData:formData];
};
[[TTNetworkManager shareInstance] setUrlHashBlock:hash];
```

- 7）设置app 基本的request & response 序列器 （**最好设置**）。 一般app都会有自己的一些对请求和响应的特殊处理， 可以放在这里

```OC
[[TTNetworkManager shareInstance] setDefaultRequestSerializerClass:[TTDefaultHTTPRequestSerializer class]];
[[TTNetworkManager shareInstance] setDefaultJSONResponseSerializerClass:[TTDefaultJSONResponseSerializer class]];
[[TTNetworkManager shareInstance] setDefaultBinaryResponseSerializerClass:[TTDefaultBinaryResponseSerializer class]];
[[TTNetworkManager shareInstance] setDefaultResponseModelResponseSerializerClass:[TTDefaultResponseModelResponseSerializer class]];
````

- 8）添加app级的响应预处理器， 可以实现响应的filter逻辑 （**可选**）

```OC
[[TTNetworkManager shareInstance] setDefaultResponseRreprocessorClass:[TTDefaultResponsePreprocessor class]];
```

- 9）可以设置一个对url预处理的回调（**可选**)

```OC
[[TTNetworkManager shareInstance] setUrlTransformBlock:^(NSURL * url){
    NSString *urlStr = [url.absoluteString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSURL *urlObj = [NSURL URLWithString:urlStr];

    if (!urlObj) {
        urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        urlObj = [NSURL URLWithString:urlStr];
    }

    urlObj = [[TTHttpsControlManager sharedInstance_tt] transferedURLFrom:urlObj];
    urlStr = urlObj.absoluteString;

    BOOL isHttps = [urlStr hasPrefix:@"https://"];
    NSURL *convertUrl = urlObj;

    if (!isHttps) {
        convertUrl = [urlObj tt_URLByReplacingDomainName];
    }

    return convertUrl;
}];
```

- 10）设置是否对请求中的敏感通用参数进行加密，比如did等（**可选**）

```OC
[TTNetworkManager shareInstance].isEncryptQueryInHeader = [TTRouteSelectionServerConfig sharedTTRouteSelectionServerConfig].isEncryptQueryInHeader;
[TTNetworkManager shareInstance].isEncryptQuery = [TTRouteSelectionServerConfig sharedTTRouteSelectionServerConfig].isEncryptQuery;
[TTNetworkManager shareInstance].isKeepPlainQuery = [TTRouteSelectionServerConfig sharedTTRouteSelectionServerConfig].isKeepPlainQuery;
```

- 11）最后调用start() 启动网络库 （**2.2.8.28版本以上必须调用**）

```OC
[[TTNetworkManager shareInstance] start];
```

## 网络库提供调用的主要API

- 主要调用接口的说明都在TTNetworkManager.h里面，这里列出几种网络请求类型的接口示例
  - JSON接口

  ```OC
  /**
  * 通过URL和参数获取JSON，支持定制header，回调里面有Response
  * @param URL                请求的URL
  * @param params             请求的参数
  * @param method             请求的方法
  * @param commonParams       是否需要通用参数
  * @param headerField        header dic
  * @param requestSerializer  设置该接口该次请求的的序列化对象, 如果传nil，用默认值
  * @param responseSerializer 设置该接口该次返回的的序列化对象, 如果传nil，用默认值
  * @param autoResume         是否自动开始
  * @param verifyRequest      是否要校验request
  * @param isCustomizedCookie 是否要使用自定义的cookie, 如果是No，则会默认携带系统cookie
  * @param callback           回调结果

  *@return TTHttpTask
  */
  - (TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                               headerField:(NSDictionary *)headerField
                         requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                             verifyRequest:(BOOL)verifyRequest
                        isCustomizedCookie:(BOOL)isCustomizedCookie
                                  callback:(TTNetworkJSONFinishBlockWithResponse)callback
  ```

  - Binary接口

  ```OC
  /**
  *  通过URL和参数请求
  *
  *  @param URL                请求的URL
  *  @param params             请求的参数
  *  @param method             请求的方法
  *  @param commonParams       是否需要通用参数
  *  @param headerField        header dic
  *  @param requestSerializer  请求的序列化对象, 如果传nil，用默认值
  *  @param responseSerializer 返回的序列化对象, 如果传nil，用默认值
  *  @param progress           progress对象
  *  @param autoResume         是否自动开始
  *  @param callback           请求的返回值
  *
  *  @return TTHttpTask
  */

  - (TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)commonParams
                                 headerField:(NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                           requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    progress:(NSProgress * __autoreleasing *)progress
                                    callback:(TTNetworkObjectFinishBlockWithResponse)callback;
  ```

  - 上传接口

  ```OC
  /**
  *
  *  @param URLString          上传URL
  *  @param parameters         参数
  *  @param headerField        HTTP 请求头部
  *  @param bodyBlock          multipart/form-data body
  *  @param progress           进度
  *  @param needCommonParams   是否需要通用参数
  *  @param requestSerializer  自定义请求序列化对象, 如果传nil，用默认值
  *  @param BINARY responseSerializer 自定义返回的序列化对象, 如果传nil，用默认值
  *  @param autoResume         是否自动开始
  *  @param callback           回调
  *  @param timeout            timeout interval in seconds, default is 30 seconds
  *
  *  @return NSURLSessionTask
  */
  - (TTHttpTask *)uploadWithResponse:(NSString *)URLString
                        parameters:(id)parameters
                       headerField:(NSDictionary *)headerField
         constructingBodyWithBlock:(TTConstructingBodyBlock)bodyBlock
                          progress:(NSProgress * __autoreleasing *)progress
                  needcommonParams:(BOOL)needCommonParams
                 requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                        autoResume:(BOOL)autoResume
                          callback:(TTNetworkObjectFinishBlockWithResponse)callback
                           timeout:(NSTimeInterval)timeout;
  ```

  - 下载接口

  ```OC
  /**
  *  download file, can get the download progress
  *
  *  @param URL              URL
  *  @param parameters       请求的参数
  *  @param headerField      HTTP header 信息
  *  @param needCommonParams 是否添加通用参数
  *  @param requestSerializer  自定义请求序列化对象, 如果传nil，用默认值
  *  @param progress         progress
  *  @param destination      文件存储位置
  *  @param completionHandler  完成后回调
  *  @return TTHttpTask
  */

  - (TTHttpTask *)downloadTaskWithRequest:(NSString *)URL
                             parameters:(id)parameters
                            headerField:(NSDictionary *)headerField
                       needCommonParams:(BOOL)needCommonParams
                      requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                               progress:(NSProgress * __autoreleasing *)progress
                            destination:(NSURL *)destination
                             autoResume:(BOOL)autoResume
                      completionHandler:(void (^)(TTHttpResponse *response, NSURL *filePath, NSError *error))completionHandler;
  ```

- Response回调block定义

  - TTNetworkJSONFinishBlockWithResponse
  
  ```OC
  typedef void (^TTNetworkJSONFinishBlockWithResponse)(NSError *error, id obj, TTHttpResponse *response);
  ```

  - TTNetworkObjectFinishBlockWithResponse

  ```OC
  typedef void (^TTNetworkObjectFinishBlockWithResponse)(NSError *error, id obj, TTHttpResponse *response);
  ```

- 几个重要的接口类，细节见具体定义
  - TTJSONResponseSerializerProtocol
  - TTBinaryResponseSerializerProtocol
  - TTHTTPRequestSerializerProtocol
  - TTResponsePreProcessorProtocol

## 组件交流反馈群

Lark搜索：ttnet ios 对接群

## 作者

zhangchenlong, zhangchenlong@bytedance.com

## 许可证

MIT
