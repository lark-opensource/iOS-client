## TTAdSplashSDK

### 简介
TTAdSplashSDK 即开屏广告 SDK。主要服务于字节系内部 App，用于展示开屏广告，统一形式与接口，避免二次开发。SDK 目前已经接入头条、抖音（dmt）、西瓜、火山等很多 App。

### 接入指南

#### 运行环境

* iOS 版本 8.0+ & Xcode 版本 8.0+
* 依赖组件：
	* JSONModel
	* TTReachability
	* libwebp (要求 1.1.0 版本及以上，头条已经升级至 1.1.0 半年以上可以直接升级）
	* TTVideoEngine
	* OpenSSL-Universal
	* MMKV

#### 导入
 在 podfile 中加入如下代码：
 ```rb
  pod_binary 'TTAdSplashSDK', '0.6.59', :subspecs => ['Core', 'Interactive']
 ```
 目前开屏分了两个 subspec, 但不是完全解耦。`Interactive` 是互动开屏的资源文件，大概有 20k 左右。业务方为避免增加不必要的包大小，可以只引入 `Core` 即可。Default 情况下同时引入 `Core` 和 `Interactive`。
 
 具体版本号如果不明确，可以咨询开发人员。
 
#### 接入流程

##### (1) 参数注册

使用 `TTAdSplashMananger` 的 `-[registerDelegate:paramsBlock:]` 方法，注册一些通用参数，同时将开屏 SDK 的通用 delegate 设置上。这些参数一般在请求打包数据时使用。主要需要传递如下参数：

```mm
[[TTAdSplashManager shareInstance] registerDelegate:self paramsBlock:^NSDictionary *{
        ...
        NSMutableDictionary *dict = @{}.mutableCopy;
        
        [dict setValue:[TTDeviceHelper openUDID] forKey:TT_OPEN_UDID];
        [dict setValue:displayDensity forKey:TT_DIS_DENSITY];
        [dict setValue:carrierName forKey:TT_CARRIER];
        [dict setValue:[TTNetworkHelper carrierMNC] forKey:TT_MCC_MNC];
        [dict setValue:[TTSandBoxHelper getCurrentChannel] forKey:TT_CHANNEL];
        [dict setValue:[TTSandBoxHelper ssAppID] forKey:TT_APP_ID];
        [dict setValue:[TTSandBoxHelper appName] forKey:TT_APP_NAME];
        [dict setValue:[TTSandBoxHelper versionName] forKey:TT_VERSION_CODE];
        [dict setValue:[TTSandBoxHelper buildVerion] forKey:TT_UPDATE_VERSION];
        NSString *platform = [UIDevice btd_isPadDevice] ? @"ipad" : @"iphone"; // 很久之前和打包约定字段为 ipad or iphone，而不是 iPad or iPhone.
        [dict setValue:platform forKey:TT_DEVICE_PLATFORM];
        [dict setValue:[UIDevice btd_platformString] forKey:TT_DEVICE_TYPE];
        [dict setValue:[UIDevice btd_currentLanguage] forKey:TT_LANGUAGE];
        [dict setValue:[[UIDevice currentDevice] systemVersion] forKey:TT_OS_VERSION];
        [dict setValue:resolutionString forKey:TT_RESOLUTION];
        [dict setValue:[UIDevice btd_MACAddress] forKey:TT_MAC_ADDRESS];
        [dict setValue:@"iOS" forKey:TT_OS];
        [dict setValue:ipString forKey:TT_IP_ADDRESS];
        [dict setValue:@([[TTLocationAdapter shared] coordinate].latitude) forKey:TT_LATITUDE];
        [dict setValue:@([[TTLocationAdapter shared] coordinate].longitude) forKey:TT_LONGITUDE];
        [dict setValue:[TTDeviceHelper idfvString] forKey:TT_IDFV];
        [dict setValue:[BDTrackerProtocol installID] forKey:TT_IID];
        [dict setValue:[BDTrackerProtocol deviceID] forKey:TT_DEVICE_ID];
        return dict;
    }];
```

##### (2) 设置开屏 SDK delegate

开屏 SDK 定义了 N 个 delegate，很多和端上的交互，都是通过这些 delegate 来完成。这个设计并不好，因为没有限制，滥用 delegate，导致现在有很多个 delegate 需要实现。后面这里需要改进。

目前 delegate 文件主要有两个：`TTAdSplashDelegate.h` 定义了大部分开屏 SDK 需要使用的 delegate；`TTAdSplashInterceptDelegate.h` 定义了原生开屏 SDK 需要使用的 delegate。

先说一下需要实现的 `TTAdSplashDelegate.h` 中的 delegate：

**@require**
* `-[splashBaseUrl]`，传递开屏数据请求的 base url，SDK 会将 base url 与 path 拼接，并添加参数进行开屏数据请求。
* `-[logoAreaHeight]`，非全屏广告时，底部区域会显示 App 的 logo，不同的 App 这个区域大小会有区别。通过这个 delegate 来传递不同机型 logo 距离广告图片底部的距离。
* `-[requestWithUrl:responseBlock:]`，这个方法用于发送网络请求，SDK 发出的所有请求，包括数据预加载、stock 接口请求、ack 接口请求等，都交给端上来处理。
* `-[requestWithUrl:method:headers:param:responseBlock:]`，类似于 `-[requestWithUrl:responseBlock:]` 方法，只不过增加了几个参数。
* `-[trackURLs:dict:]`，主要用于检测链接上报，不实现的话所有监测链接都不会上报。
* `-[trackWithTag:label:extra:]`，主要用于埋点数据上报，不实现的话所有埋点不会上报。
* `-[splashActionWithCondition:]`，主要用于响应广告点击事件。点击开屏后将参数传递给端上，端上进行跳转处理。
* `-[splashLogoViewWithColor:]`，全屏开屏广告，左上角的 logo。这个 logo 通过端上传入，而且可以通过 SDK 传过来的不同枚举，返回不同的 logo 视图。
* `-[splashFakeLaunchView]`，一个假启动图。在 App 启动图消失到开屏展示这段过程中，可能会有间隙，导致先展示主界面再展示开屏。为了避免这个问题，加一个启动图在这期间，这个启动图由端上传入。
* `-[splashBGViewWithFrame]`，开屏广告的一个背景图，当展示半屏广告时候，底部会露出 App 的 logo。有的 App 这个图和启动图一样（启动图的 logo 就在底部，例如头条），有的不一样（启动图的 logo 不再底部，例如抖音）。
* `-[displayContentMode]`，开屏广告展示 mode，拉伸铺满还是居中裁剪，目前大部分客户端都是居中裁剪，即 `TTAdSplashDisplayContentModeScaleAspectFill`。
* `-[monitorService:value:extra:]`，端监控数据上报，SDK 会进行一些性能打点，通过这个接口进行上报。
* `-[splashNetwokType]`，当前网络状态，用于请求数据时传递给打包。
* `-[deviceId]`，用户设备 id，用于请求数据时传递给打包。
* `-[installId]`，install id，用于请求数据时传递给打包。

**@optional**
* `-[splashDebugLog]`，开屏调试日志，可以在测试环境打开，用于排查开屏展示问题。
* `-[enableSplashLog]`，调试日志开启开关，配合 `-[splashDebugLog]` 使用，设计之初的一个开关，后面会去掉。
* `-[skipButtonBottomOffsetWithBannerMode]`，跳过按钮在底部时，详细的高度，需要根据 UI 给出的设计稿来定，如果 UI 没有给，可以按照头条的来设计。
* `-[splashViewWillAppear]`，开屏将要展示回调，即将废弃。
* `-[splashViewWillAppearWithAdModel:]`，开屏将要展示回调，带参数。
* `-[splashViewAppearWithAdInfo:]`，开屏广告展示回调，带上 ad_id 等参数。
* `-[splashViewDidDisappearWithAdModel:]`，开屏结束展示回调。
* `-[preloadSplashAdMpURLList:]`，开屏预加载小程序接口，如果想要投放小程序相关广告，可以通过这个 delegate 来对小程序进行预加载。
* `-[preloadSplashAdWebSplashList:]`，开屏预加载 webview 接口。
* `-[topViewSDKPreloadEnable]`，是否在端上进行炫屏视频预加载。
* `-[preloadVideoWithCondition:completionBlock:]`，预加载炫屏开屏视频数据。
* `-[removeTopViewResource:]`，移除炫屏开屏数据。
* `-[isVideoPreloadSuccess:videoId:]`，检测炫屏视频是否预加载成功。
* `-[shouldDisplayPersonalizedAd:]`，是否展示个性化广告，对于隐私比较敏感的地区，return NO。

关于原生开屏(炫屏)的 delegate，后面在介绍原生开屏接入的时候详细说。

##### (3) 设置开屏开关
开屏 SDK 之前开了很多个实验，所以需要设置很多开关。目前有些实验已经全量，会逐步下掉旧实验，减少设置开关工作量。在此之前，还需要端上来设置。

* ignoreFirstLaunch，是否忽略手刷，默认为 YES，即不启用首刷逻辑。如果需要开启，需要设置为 NO。
* isEnableFirstLaunchRetrieval，是否启用手刷回捞机制，如果启用手刷机制，此开关建议设置为 YES。
* isNewAdStyleEnable，广告新样式开关，建议设置为 YES，目前各端8都在使用新样式。

##### (4) 触发开屏展示
组要在**冷热启动**的时候，调用开屏展示接口 `-[displaySplashOnWindow:splashShowType:isHotLaunch:]`，触发开屏展示，。eg:

```mm
// window 为业务方想要展示的层级，一般为 keyWindow.
// 建议传上是否冷热启参数。
[[TTAdSplashManager shareInstance] displaySplashOnWindow:window splashShowType:TTAdSplashShowTypeShow isHotLaunch:isHotLaunch];
```

处理完这四个步骤之后，开屏基本可以正常展示。因为直接贴 mock 数据，可能会过期。你可以通过在头条 App 上面预览以下数据(预览 id 不是创意 id 就是计划 id)，然后进行抓包，直接 map local，或者直接找服务端要数据。

> 广告预览平台: https://adstyle.bytedance.net/preview

* 图片广告预览 id:  1650894830030856
* 视频开屏广告预览 id: 1630506719614011

或者你可以在预览平台的 创意列表->请选择资源位 的里面，进行 App & 位置检索，预览一个创意。

开屏展示情况如下：

广告样式 | 预览图
--------- | -------------
全屏图片 | <div align=center> <img src="./Doc/images/fullScreenImage.png" width="375" height="812" /> </div>
半屏图片 | <div align=center> <img src="./Doc/images/noFullScreenImage.png" width="375" height="812" /> </div>
全屏视频 | <div align=center> <img src="./Doc/images/fullScreenVideo.png" width="375" height="812" /> </div>

#### 支持原生开屏（又叫 Topview, 炫屏）

原生开屏是指由 SDK 提供数据，由端上渲染视图的开屏，目前支持视频和图片两种格式。头条 App 目前的整体设计思路是：

* 满足展示 topview 条件（feed 有刷新，在推荐频道）后，从开屏 SDK 获取满足条件的数据，并根据数据渲染出 view; 不满足前面的条件，尝试展示普通开屏。
* 将渲染的 view 加到 window 上进行展示。与此同时，feed 数据正在请求刷新。
* 展示结束时，从 feed 返回的数据中查找对应的数据。通过 SDK 的 `splash_ad_id` 字段与 feed 上某个字段（具体与客户端打包确定）关联起来。找到数据做联动动画；找不到直接展示结束。
* 动画结束时，将播放器赋值到 cell 上，移除 topview. 头条的 topview 和 feed 上的 cell，使用的同一个播放器，这样动画过渡过去之后，可以无缝续播。

想要接入原生开屏，在进行完上一步的基础上，需要做如下工作：

##### 1. 前置操作

如果 App 之前接入过开屏 SDK，原来的初始化开屏 SDK 逻辑保留，原来的普通开屏展示逻辑保留。判断本次为 topview 广告，走 topview 的逻辑；否则走原来的普通开屏逻辑。

##### 2. 获取渲染 topview 的数据 model

客户端通过 `-[pickOriginalAdWithCheckArea:]` 方法获取数据 model。其中传入的参数为一个 block，客户端在 block 中进行额外条件判断，符合条件的话 return YES.

在 pick model 的时候，SDK 会做一下逻辑判断：

* 广告是否过期
* 广告是否开始
* 频控 - 展示间隔是否满足条件。最少 10min，最大由服务端下发的 `splash_interval` 字段控制，这个校验在热启动时才有效，冷启动会一直校验通过，返回 YES.
* 频控 - 进入后台时间是否满足条件。最少 30s，最大由服务端下发的 `leave_interval` 字段控制，这个校验在热启动时才有效，冷启动会一直校验通过，返回 YES.
* 素材是否已经缓存到本地。
* 是否只在 WiFi 条件下展示，由 `wifi_only` 控制，默认 NO.

**其余条件由客户端在 block 中校验**. 例如是否刷新、是否在推荐频道等条件。

调用 pick 方法之后，需要调用一次 `-[displaySplashOnWindow:splashShowType:]` 方法. 这里面会进行埋点上报。下面是头条中的调用逻辑 ： 

```mm
/** 展示开屏 */
- (BOOL)displaySplashOnWindow:(UIView *)keyWindow
               splashShowType:(TTAdSplashShowType)type
                  isHotLaunch:(BOOL)isHotLaunch {
                  
	/* 一些初始化，开关等逻辑，和来开屏展示保持一致 ... */
	
	TTAdSplashModel *model = nil;
	// 一次展示机会，只能 pick 一次，如果其他地方 pick 过了，这里直接复用。头条这里有时候会在请求 feed 上 pick，然后这里直接复用。
	if (![TTAdTopViewManager sharedManager].isPicked) {
	   model = [[TTAdSplashManager shareInstance] pickOriginalAdWithCheckArea:^BOOL(TTAdSplashModel *model) {
	   // 这里端上校验了 model 是否为空，是否触发了刷新，是否在推荐频道等逻辑。
	       return [[TTAdTopViewManager sharedManager] shouldDisplayTopViewWithModel:model isHotLaunch:isHotLaunch];
	   }];
	   // 筛选完了 model 就置为 NO
	   [TTAdTopViewManager sharedManager].isAutoRefresh = NO;
	   [TTAdTopViewManager sharedManager].splashModel = model;
	} else {
	   model = [TTAdTopViewManager sharedManager].splashModel;
	}
	    
	if (model) { // 如果 model 不为空, 展示 topview
	   return [self showTopViewWithModel:model
	                              window:keyWindow
	                         isHotLaunch:isHotLaunch];
	} else {	// 否则展示普通开屏
	   return [self showNormalSplashWithWindow:keyWindow splashShowType:type];
	}
}

/** 展示霸屏开屏，有客户端展示 */
- (BOOL)showTopViewWithModel:(TTAdSplashModel *)model
                      window:(UIView *)window
                 isHotLaunch:(BOOL)isHotLaunch {
    // 去重判断，防止出现多个 topview
    if ([TTAdTopViewManager sharedManager].adWillShow) {
        return NO;
    }
    // 调用客户端渲染逻辑
    BOOL result = [[TTAdTopViewManager sharedManager] showTopViewWithModel:model isHotLaunch:isHotLaunch];
    // 调用 SDK 的 display 方法，里面会上报一些埋点
    [[TTAdSplashManager shareInstance] displaySplashOnWindow:window splashShowType:TTAdSplashShowTypeShow];
   
    return result;
}

/** 展示普通开屏，由 SDK 去展示 */
- (BOOL)showNormalSplashWithWindow:(UIView *)keyWindow splashShowType:(TTAdSplashShowType)type {
    [[TTAdSplashManager shareInstance] displaySplashOnWindow:keyWindow splashShowType:type];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self detectCallbackFromThirdApp];
    });
    
    return YES;
}
```

##### 3. topview 的渲染

topview 上面的所有控件都由客户端自己渲染， 包括视频、logo、跳过按钮、WiFi 预加载等。样式由客户端 UI 确定。

model 中的数据使用：

* 广告创意对应的 id 是 `splashID` 这个属性，不是 `splashAdId`。后者是与 feed 广告关联的字段。
* 开屏展示时间由 `display_time_ms` 字段确定，对应属性为 `displayTime`。使用这个字段时，最好和视频时间做一个校验，即 `MIN(splashModel.displayTime, 视频时长)`, 虽然大多数视频时长都是大于 `displayTime`。
* 视频资源由 SDK 进行预加载，获取时通过 `[TTAdSplashCache cachePath4VideoWithVideoId:]` 方法获取一个本地路径，然后进行初始化。
* 视频其他信息，在开屏数据的 `video_info` 字段中。可以通过 `TTAdSplashModel` 属性获取。
* 点击事件，会使用 model 数据中的 `web_url`、`open_url`、`download_url`、`appleid` 等字段。

渲染出 view 之后，加到 window 上进行展示。此时需要调用 `[TTAdSplashManager saveSSADRecentlyShowSplashADTime];` 方法保存一下时间，用于下次频控计算。建议自行维护一个当前有广告展示的标志位，不要有 SDK 中自带的 `isAdShowing`.

**展示 topview 之后，需要客户端调用 -[sendAwesomeSplashACK] 方法告诉打包，topview 已经展示。这个方法一定要在调用 -[displaySplashOnWindow:splashShowType:] 之前调用。**

一些坑：

* 展示 topview 的时候，是不能展示 status bar 的，客户端需要在合适的时机隐藏和显示。
* 视频最好和 feed 用同一个播放器，动画结束后赋值个 feed，如果用两个播放器，续播可能会卡顿。
* topview 展示的时候，不能展示音量、进度条、全屏等控制按钮，到 feed 上才能展示。
* 如果用的公司的播放器，播放本地视频时，需要通过类似 `-[setDirectURL:]` 方法将本地视频 path 传给播放器。如果像赋值远端 URL（https 那个） 那样初始化播放器，**可能看不到进度条**。
* 进入后台；点击 topview 跳转；点击跳过，均中断视频播放展示。

##### 4. topview 展示结束时，进行动画过渡

针对头条，是在展示 topview 的同时，进行 feed 刷新。展示结束之后，如果能在 feed 返回数据中找到对应广告，则做联动动画；如果 feed 此时未返回，或者返回数据中没有对应广告，直接开屏展示结束。如果其他 App 是 feed 刷新之后才展示 topview, 可以不考虑这一点。

topview 和 feed 上的广告，公用的是同一份视频。打包下发的原视频是 feed 上的视频。展示的时候，把 feed 上视频等比拉伸，使其高度等于 topview 高度，宽度超出屏幕外，填充到 topview 展示。做动画的时候再变换回来，大概如下面这样：

![topview拉伸](./Doc/images/topview拉伸.jpg)


做过渡动画时，feed 上对应的广告 cell 应该已经渲染出来，否则无法计算 cell 的位置。在头条中，使用 `CABasicAnimation` 进行的 layer 动画。因为播放器本身是一个 layer，如果用 `UIView` 动画达不到效果。

关于计算动画变化的新 frame。使用 `CABasicAnimation` 要想达到效果，需要做 `transform` 动画。计算 position.y 的时候需要注意：因为在 x, y 方向需要进行缩放，y 轴的缩放本身会影响 position.y 的值，所以不能直接将 cell 对应的 y 坐标直接设置为 position.y。

例如，开始时 topview y 坐标是 0，高度为 200，cell y 坐标是 100。y 轴方向缩小 0.5 倍，此时 topview 的 y 坐标变为 50. 如果想最终让 y 坐标变为 100，动画的 position.y 应该为 50，而不是 100。下面是头条的设置代码：

```mm

CGFloat height = feedAdFrame.size.height;
CGFloat width = feedAdFrame.size.width;
CGFloat offsetY = feedAdFrame.origin.y;
CGFloat offsetX = feedAdFrame.origin.x;
    
// 水平方向缩放幅度
CGFloat scaleX = width / self.topView.width;
// 竖直方向缩放幅度
CGFloat scaleY = height / self.topView.height;
// 新的 Y 坐标. 计算规则：原始坐标 + 期望位移 - 因为缩放导致的位移
CGFloat newPositionY = self.topView.layer.position.y + (offsetY - self.topView.top - self.topView.height * (1 - scaleY) / 2);
    
CAAnimationGroup *animationGroup = [CAAnimationGroup new];
animationGroup.duration = animatedDuration;
animationGroup.delegate = self;
animationGroup.repeatCount = 1;
animationGroup.removedOnCompletion = NO;
animationGroup.fillMode = kCAFillModeForwards;
animationGroup.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.4 :0.8 :0.74 :1];
CABasicAnimation *animation1 = [CABasicAnimation animationWithKeyPath:@"position.y"];
animation1.fromValue = @(self.topView.layer.position.y);
animation1.toValue = @(newPositionY);

CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
animation2.fromValue = @(1);
animation2.toValue = @(scaleX);

CABasicAnimation *animation3 = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
animation3.fromValue = @(1);
animation3.toValue = @(scaleY);

animationGroup.animations = @[animation1, animation2, animation3];
[self.topView.layer addAnimation:animationGroup forKey:nil];
```

做完动画后，处理各种状态，例如播放器显示控制按钮等。

一些坑：

* 开始做动画的时候，要隐藏 logo，跳过按钮等 view，否则会很难看。
* 做动画的时候，topview 不能响应点击事件，动画结束后需要设置回来。
* 对于 feed cell 只露出一半，被 tab bar 遮挡的时候，动画效果很差。此时需要将 tab bar 做一个截图，贴在 topview 底部，动画结束后移除，这样效果会好一些。

##### 5. 埋点上报

topview 的展示、播放、播放结束、播放中断，都应该进行埋点数据上报。可以使用如下接口：

```mm
/**
 上报原生开屏视频广告播放中断，中断的类型定义请见`TTAdSplashVideoBreakReason`

 @param reason 中断的原因
 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data
 */
- (void)trackOriginalAdPlayBreakWithReason:(TTAdSplashVideoBreakReason)reason
                                     model:(TTAdSplashModel *)model
                                     extra:(NSDictionary *)extra
                               adExtraData:(NSDictionary *)adExtraData;;

/**
 上报原生开屏视频广告开始播放

 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data
 */
- (void)trackOriginalAdPlayWithModel:(TTAdSplashModel *)model
                               extra:(NSDictionary *)extra
                         adExtraData:(NSDictionary *)adExtraData;


/**
 上报原生开屏视频广告播放失败

 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data */
- (void)trackOriginalAdPlayFailWithModel:(TTAdSplashModel *)model
                                   extra:(NSDictionary *)extra
                                   adExtraData:(NSDictionary *)adExtraData;

/**
 上报原生开屏视频广告全部时长播放完毕

 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data*/
- (void)trackOriginalAdPlayOverWithModel:(TTAdSplashModel *)model
                                   extra:(NSDictionary *)extra
                             adExtraData:(NSDictionary *)adExtraData;


/**
 上报原生开屏展示失败原因, 宿主 App 和 SDK 分别上报自己的原因

 @param tag 客户端和 SDK 同不同的 tag, 客户端是 'embeded_ad', SDK 是 'splash_ad'
 @param model 当前播放的视频广告对应的model
 @param extra 需要透传的字段, value为 String Number
 @param adExtraData 对应 ad_extra_data
 */
- (void)trackOriginalAdShowFailWithTag:(NSString *)tag
                                 model:(TTAdSplashModel *)model
                                 extra:(NSDictionary *)extra
                           adExtraData:(NSDictionary *)adExtraData;
```

> click 事件放在了上报 play_break 事件的方法里，当初不清楚为什么要放在一起，后面需要拆出来，分开上报好一些。

### 开屏 SDK 额外支持的一些功能

#### 1.实时开屏 & 停投
开屏 SDK 目前支持实时开屏，主要策略是数据和素材提前预加载，然后每次触发开屏展示时，通过 UDP 请求拿到一个创意 ID，然后本次展示这个创意 6ID。但是成功率比较低 60%~80% 左右，还在优化中。停投也比较依赖 UDP 返回情况，不能全部停住，待优化。接入方式:

```mm
// settings 开关控制是否启用实时开屏
if (ttas_isSplashRealtimeFetchEnable()) {
    [TTAdSplashManager shareInstance].enableRealTimeFetch = YES;
}

// settings 控制 udp 请求 ip 列表
NSArray *ipList = ttas_udpfetchcommandIPlist();
if (ipList) {
    [TTAdSplashManager shareInstance].ipList = ipList;
    // 设置停投
    [[TTAdSplashManager shareInstance] setShouldFetchCmdBeforeShowingSplashAd:YES withAppId:[TTSandBoxHelper ssAppID]];
}
[TTAdSplashMediator adSplashControlCdnExperiment];
```

#### 2.素材保密性

为了防止素材泄密，引起法务风险，SDK 做了一些处理，主要是在两个方面进行防护:

##### (1) 时间校验处理
普通情况下，用户通过调整时间，可以看到未来时间的广告。添加时间校验之后，本地会保留一个相对时间戳，无论如何调整时间，都以取得是真实时间来校验数据，不会因为调整时间提前暴露素材。如果想要开启此功能，需要将 `isEnableTimeCheck` 设置为 YES，eg:

```mm
[TTAdSplashManager shareInstance].isEnableTimeCheck = YES;
```

##### (2) 素材加密

由服务端对数据进行加密，SDK 对数据进行解密并展示。图片数据由 SDK 调用 openssl 接口封装了解密算法；视频数据使用公司自研播放器进行解密。是否开启加密，由服务端控制，在 `image_info` 或者 `video_info` 中下发 `secret_key` 即走加密逻辑。

如果要启用视频素材加密，一定要在展示开屏之前，初始化公司自研播放器。如果端上已经初始化了，则不用管；如果端上没有初始化，需要调用开屏 SDK 的 `-[startOpenGLESActivityForSplash]` 和 `-[stopOpenGLESActivityForSplash]` 两个方法，具体使用见注释。

加密之后，第三方通过抓包拿到链接，或者获取 App 沙盒文件，均不能查看素材。

### SDK 联系人
联系人 | 角色 | 邮箱
|:--:|:--:|:---------:|
| 周博 | RD-iOS | zhoubo.bool@bytedance.com |
| 孙海源 | RD-Android | sunhaiyuan@bytedance.com |
| 张至权 | RD-Android | zhangzhiquan.0707@bytedance.com |
| 刘佳 | RD-Server | liujia.rd@bytedance.com |
| 王岩 | RD-Server | wangyan.z@bytedance.com |
| 朱鲁斌 | PM | zhulubin@bytedance.com |
| 张强 | QA | zhangqiang.5230@bytedance.com |

### CHANGELOG

[详情请点击这里](./CHANGELOG.md)

### FAQ

#### 1.mock 了相关数据，但是开屏一直无法展示。

可以通过实现 `-[enableSplashLog]` 返回 YES，并且实现 `-[splashDebugLog]` 输出日志，可以直接用 `NSLog()` 输出，或者其他展示形式。然后用 `[BDASplash]` 进行 filter。日志里面会显示各种失败原因。

可能是因为频控、素材下载失败、首刷等原因导致不展示。

#### 2.开屏 SDK 分支 tag 提供问题。

需求开发期间，由 SDK 维护人员提供分支或者 alpha tag，然后正式发版的时候，提供正式 tag。线上正式发版只能是正式 tag 或者 bugfix 类型 tag，不可以是 alpha tag 或者 rc 类型 tag。

#### 3.开屏也没上面的元素问题。

开屏 SDK 的 logo，点击跳过，WiFi 预加载这几个元素，都是服务端可控制的，logo 通过下发不同的枚举，控制不同样式；点击跳过、WiFi 预加载都可以动态控制文案、文字颜色、位置。

#### 4.libwebp 组件问题

因为开屏 SDK 支持了 WebP 图片，里面封装了一套 WebP 编解码功能，所以引入了这个组件。而且**需要 1.1.0 版本及以上**。头条主端已经升级到 1.1.0 版本很久（半年以上），所以可以放心升级。

#### 5.关于国际化 App 接入开屏 SDK

国际化有单独的仓库 : [BDASplashSDKI18N](https://code.byted.org/TTIOS/BDASplashSDKI18N)。内容和 TTAdSplashSDK 一样，只是做了脱敏处理。

#### 6.关于开屏数据请求接口

首先在注册 SDK 时候，一定要传 'app_name' 参数。然后请求的时候会拼接到 path 上面。path 格式是 '/api/ad/splash/app_name/v15/'。如果不传 'app_name' 参数，path 的 'app_name' 位置为空，请求数据会有问题。

传递参数没问题之后，直接 Charles 抓包即可。

#### 7.关于 Dark Mode

开屏没有 Dark Mode，不用考虑适配问题。

#### 8.关于埋点问题

对于普通开屏，SDK 内部发了 play、show、click 等计费埋点，以及 preload、download 等 debug 埋点。同时也发送了监测链接请求，端上不用管。但是点击之后的行为，是端上处理的，所以点击行为之后的（例如跳转 web 还是 app) 的埋点需要端上处理。

对于原生开屏，因为 view 的渲染展示都是端上做的，所以需要端上调用 SDK 借口触发埋点上报。

#### 9.如何监听开屏的展示情况

有两种方法，第一你可以通过 `TTAdSplashDelegate.h` 中的 `-[splashViewWillAppear]` 等一系列方法进行监听。

第二你可以通过 `kTTAdSplashShowStart` 和 `kTTAdSplashShowFinish` 两个通知来监听。

#### 10.开屏声音问题

通常情况下，开屏没有声音，而且开屏启动的时候，会设置全局声音选项关闭；开屏展示结束后，**不会**把这个选项恢复。避免引起一些异常情况。

#### 最后：开屏的需求为什么迭代这么慢

接入业务方太多，需求太多，人力不够，多给我们推几个人就好了。

#### 持续补充...

