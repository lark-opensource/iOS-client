### 简介

- TTVideoEngine是iOS和Android客户端中使用的通用点播SDK， 它旨在帮助开发者迅速完成视频点播业务的开发。开发者只需要调用几个接口就能轻松实现视频播放的逻辑，并且能实时统计视频播放的质量。这篇文章将简要介绍TTVideoEngine的使用方法。

### 版本对接

版本对接请看版本发布记录文档 https://bytedance.feishu.cn/docs/doccnsjLBNGNtdmlQYy7lL#

对于出现在 bytebus 版本历史中的版本，除非被标记为稳定版本或者推荐版本，否则请不要在线上业务中使用。

版本对接其他问题请使用 @视频云-点播OnCall

### 安装

- 目前TTVideoEngine支持通过[CocoaPods](https://cocoapods.org)的方式安装，支持iOS 7及以上。
只需要简单的在Podfile中添加以下一行:

```c
source 'git@code.byted.org:TTVideo/ttvideo-pods.git'
pod 'TTVideoEngine', '1.8.1.3'
pod 'TTPlayerSDK', '2.8.1.38'
```
然后在命令行中输入 pod install 即可给你的工程添加好依赖。
想了解更多关于CocoaPods的内容，可以看这些[教程](https://guides.cocoapods.org/using/getting-started.html)。



### 接口文档

- [接口文档]()

### 使用

1.TTVideoEngine的初始化

应用becomeActive需要激活OpenGLES环境，应用resignActive需要关闭OpenGLES

```objective-c
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    [TTVideoEngine stopOpenGLESActivity];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [TTVideoEngine startOpenGLESActivity];
}
```

**注: startOpenGLESActivity和stopOpenGLESActivity需要在app delegate里面调用,并且需要放在函数的第一行，不要使用通知监听的方式，否则会有crash或是黑屏**

有多种不同的方式为播放器提供播放数据。

- video ID

```c
TTVideoEngine *videoEngine = [[TTVideoEngine alloc] init];
[videoEngine setVideoID:vid];
```
TTVideoEngine初始化需要设置视频的vid，同时客户端还需要如下协议:

```c
@protocol TTVideoEngineDataSource <NSObject>

@required
- (NSString *)apiForFetcher;
@end
```
该协议要求客户端返回请求play的接口的api string

- 直接用视频的URL播放

```objective-c
[videoEngine setDirectPlayURL:url];
```

- 播放本地视频文件

```
[videoEngine setLocalURL:@"file:///User/../localfile.mp4"];
```

- 使用预加载

  如果使用预加载，需要依赖`TTPreloaderSDK`，预加载完成后可以获取`TTPreloaderItem`对象，可以使用这个对象播放视频。预加载可以减小视频播放的首帧时间。

  使用预加载也需要实现`TTVideoEngineDataSource`协议。

  ```objective-c
  [videoEngine setPreloaderItem:preloadItem];
  ```
  
- 使用feed下发
    
  如果要使用feed下发播放，需要实现`TTVideoEngineDataSource`协议，同时需要给videoEngine传入一个TTVideoEngineVideoInfo类型的模型数据:
  
  ```
  [videoEngine setVideoInfo:videoInfo];
  ```
  
  TTVideoEngineVideoInfo包含有vid，resolution, expire(过期时间戳，精确到秒)以及一个feed下发的模型数据(内部包含不同清晰度的url)
  
  ```
  @interface TTVideoEngineVideoInfo : NSObject
  @property (nonatomic, strong) NSString *vid;
  @property (nonatomic, assign) TTVideoEngineResolutionType resolution;
  @property (nonatomic, assign) long long expire;
  @property (nonatomic, strong) TTVideoEnginePlayInfo *playInfo;
    
  - (BOOL)isExpired;
    
  - (BOOL)hasPlayURL;
    
  @end
  ```
  
2.添加播放器视图

```c
[self.view addSubview:videoEngine.playerView];
```
只需要将播放器视图添加到你想要的展示界面上即可，播放器会自适应播放画面。

3.控制播放行为

```c
/**
It's used to play video. You can use it to start or resume the player.
Make sure you've already called setVideoID: method
*/
- (void)play;

/**
 It's used to pause the video playing.
 */
- (void)pause;

/**
 It's used to stop the video and it will reset the internal player.
 */
- (void)stop;
```
play接口用于控制播放器开始播放或者从暂停状态恢复， pause接口用于暂停视频播放，stop接口用于终止视频的播放。

4.监听播放状态
   
   通过设置videoEngine的delegate便可监听播放的状态，以下是videoEngine delegate的定义：

```c
@protocol TTVideoEngineDelegate <NSObject>

@optional

- (void)videoEngine:(TTVideoEngine *)videoEngine playbackStateDidChanged:(TTVideoEnginePlaybackState)playbackState;
- (void)videoEngine:(TTVideoEngine *)videoEngine loadStateDidChanged:(TTVideoEngineLoadState)loadState;
- (void)videoEngineReadyToPlay:(TTVideoEngine *)videoEngine;
 
@required

- (void)videoEngineUserStopped:(TTVideoEngine *)videoEngine;
- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine error:(NSError *)error;
- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine videoStatusException:(NSInteger)status;
@end

@property (nonatomic, weak) id<TTVideoEngineDelegate> delegate;
```
- -(void)videoEngine:(TTVideoEngine *)videoEngine playbackStateDidChanged:(TTVideoEnginePlaybackState)playbackState 

  这个方法会通知你播放器播放状态的变化

```
typedef NS_ENUM(NSInteger, TTVideoEnginePlaybackState) {
    TTVideoEnginePlaybackStateStopped,
    TTVideoEnginePlaybackStatePlaying,
    TTVideoEnginePlaybackStatePaused,
    TTVideoEnginePlaybackStateError,
};
```
**注: 一般只需用到这两个状态TTVideoEnginePlaybackStatePlaying(表示播放中)和TTVideoEnginePlaybackStatePaused(表示暂停)**

- -(void)videoEngine:(TTVideoEngine *)videoEngine loadStateDidChanged:(TTVideoEngineLoadState)loadState 
  
  这个方法会通知你播放器加载状态的变化，你可以用它来做加载缓冲的动画等

```
typedef NS_ENUM(NSUInteger, TTVideoEngineLoadState) {
    TTVideoEngineLoadStateUnknown        = 0,
    TTVideoEngineLoadStatePlayable,
    TTVideoEngineLoadStateStalled,
    TTVideoEngineLoadStateError,
};
```

**注: 一般只需用到这两个状态:TTVideoEngineLoadStatePlayable(表示可播放，不需要loading动画)和TTVideoEngineLoadStateStalled(表示加载中，需要显示loading)**

- -(void)videoEngineReadyToPlay:(TTVideoEngine *)videoEngine 

  这个方法用于通知你视频即将开始播放


**注: 以下三个回调都是播放结束的回调，是必须要实现的，他们之间是并列的关系**

- -(void)videoEngineUserStopped:(TTVideoEngine *)videoEngine;
  
  表示用户主动退出播放

- -(void)videoEngineDidFinish:(TTVideoEngine *)videoEngine error:(NSError *)error; 

  该方法用于通知你播放完成，你可以根据error是否为空判断是否需要展示错误信息。

- -(void)videoEngineDidFinish:(TTVideoEngine *)videoEngine videoStatusException:(NSInteger)status
  
  该方法用于表示视频的状态异常
  

5.播放进度条
   
   播放器进度条相关的属性有当前播放时间、视频总时长、缓冲时长:

```c
@property (nonatomic, assign, readonly) NSTimeInterval currentPlaybackTime;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval playableDuration;
```
以下两个方法可用于周期性监听播放器的播放进度、缓冲进度等信息

```c
/**
 It's used to periodicly get something from the player, such as current currentPlaybackTime, playableDuration...

 @param interval the time interval in seconds
 @param queue target queue to perform action
 @param block periodic work to do
 */
- (void)addPeriodicTimeObserverForInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)())block;

/**
 remove the observer
 */
- (void)removeTimeObserver;
```
通过addPeriodicTimeObserverForInterval方法建立周期性观察，在block里面获取播放器的播放进度信息等用于展示，最后再通过removeTimeObserver释放观察者。

6.多清晰度切换

  与清晰度切换相关的有如下两个方法:

```c
/**
 It's used to get the supported resolutions for the video

 @return an Array of numbers(TTVideoEngineResolutionType)
 */
- (NSArray<NSNumber *> *)supportedResolutionTypes;

/**
 It's used to set the default resolution and it can also used to switch resolution

 @param currentResolution the default resolution, or the resolution to switch
 */
- (void)setCurrentResolution:(TTVideoEngineResolutionType)currentResolution;
```
supportedResolutionTypes可以返回当前支持的清晰度，setCurrentResolution可以用于指定想要设置的清晰度，如果当前清晰度与你指定的清晰度不一致则会发生清晰度的切换。

7.播放日志调试

  默认播放器的调试日志处于关闭状态，你可以通过如下方法打开播放器的调试日志:

```c
/**
 This method is used to enable or disable log

 @param enabled YES to enable log
 */
+ (void)setLogEnabled:(BOOL)enabled;
```

只需要将enalbed设置为YES即可打开调试日志。

### 日志上传

- videoEngine会在播放完成、失败、seek、清晰度切换、手动停止播放等场景下产生log事件，产生的log会通过回调的方式通知给客户端，客户端可以将接收到的事件上传到app log，便于后续播放质量相关的统计分析。

- 使用方式

  与日志相关的类是TTVideoEngineEventManager，它是一个单例，可以通过设置它的delegate来监听log事件
  
  ```
  - (void)eventManagerDidUpdate:(TTVideoEngineEventManager *)eventManager;
  ```
  
  这是delegate的回调，每当播放器产生新的日志就回调用这个方法，客户端需要实现这个方法，同时在里面调用`- (NSArray<NSDictionary *> *)popAllEvents`来获取日志
- 参考代码
  
  ```
  - (void)eventManagerDidUpdate:(TTVideoEngineEventManager *)eventManager
{
        NSArray *dics = [eventManager popAllEvents];
        for (NSDictionary *dic in dics) {
            [[SSLogDataManager shareManager] appendLogData:dic];
        }
}
    
    [[TTTracker sharedInstance] setCustomEventBlock:^(void) {
        NSMutableDictionary *eventDic = [NSMutableDictionary dictionary];
        [eventDic setValue:[[SSLogDataManager shareManager] needSendLogDatas] forKey:@"log_data"];
        
        return [eventDic copy];
    }];
  ```

### 支持&维护

桂琨智 guikunzhi@bytedance.com

钟少奋 zhongshaofen@bytedance.com

陶海庆 taohaiqing@bytedance.com



