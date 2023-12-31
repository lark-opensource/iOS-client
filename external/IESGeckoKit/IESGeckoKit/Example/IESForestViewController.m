#import "IESForestViewController.h"
#import "IESForestKit+private.h"
#import <IESGeckoKit/IESForestResponseProtocol.h>
#import <IESGeckoKit/IESForestRequest.h>
#import <IESGeckoKit/IESForestResponse.h>
#import <IESGeckoKit/IESForestKit.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <IESGeckoKit/IESForestPreloadConfig.h>

#pragma mark - CustomFetcher
@interface CustomResponse : NSObject <IESForestResponseProtocol>
@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) NSString *accessKey;
@property (nonatomic, copy) NSString *bundle;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *sourceUrl;
@property (nonatomic, copy) NSString *absolutePath;
@property (nonatomic, assign) NSInteger *version;
@property (nonatomic, assign) IESForestDataSourceType sourceType;
@end

@implementation CustomResponse
@synthesize debugInfo;
@synthesize expiredDate;
@synthesize fetcher;
@end

@interface CustomFetcher : NSObject <IESForestFetcherProtocol>
@end

@implementation CustomFetcher

- (NSString *)name
{
    return @"CustomFetcher";
}

- (void)cancelFetch {
    NSLog(@"Can't cancel fetch");
}

- (void)fetchResourceWithRequest:(nonnull IESForestRequest *)request completion:(nullable IESForestFetcherCompletionHandler)completion {
    CustomResponse *response = [[CustomResponse alloc] init];
    NSString *aString = @"Hello, I am the content of custom fetcher!";
    response.data = [aString dataUsingEncoding: NSUTF8StringEncoding];
    response.sourceType = IESForestDataSourceTypeOther;
    completion(response, nil);
}

@end

#pragma mark - CustomInterceptor
@interface CustomInterceptor : NSObject <IESForestInterceptor>
@end

@implementation CustomInterceptor
- (NSString *)interceptorName
{
    return @"customInterceptor";
}

- (void)willFetchWithURL:(NSString *)url parameters:(IESForestRequestParameters *)parameters
{
    NSLog(@"will fetch");
}

- (void)didCreateRequest:(IESForestRequest *)request
{
    NSLog(@"didCreateRequest: can change request here");
    IESForestFetcherID customFetcherID = [IESForestKit registerCustomFetcher:[CustomFetcher class]];
    request.disableGecko = YES;
    request.disableCDN = YES;
    // add customFetcher into fetcherSequence
    NSMutableArray *seq = [NSMutableArray arrayWithArray:request.fetcherSequence];
    [seq addObject:@(customFetcherID)];
    request.fetcherSequence = seq;
}

- (void)didFetchWithRequest:(IESForestRequest *)request response:(id<IESForestResponseProtocol>)response error:(NSError *)error
{
    if (response && response.data) {
        NSLog(@"did fetch response.data.length: %ld", response.data.length);
    }
    NSLog(@"Error!");
}
@end

@interface IESForestViewController ()

@property (nonatomic, copy) NSArray<UIButton *> *buttons;
@property (nonatomic, strong) IESForestKit *customForest;

@end

#pragma mark - Monitor

@interface CustomMonitor : NSObject <IESForestEventMonitor>
@end

@implementation CustomMonitor
- (void)monitorEvent:(nonnull NSString *)event data:(NSDictionary * _Nullable)data extra:(NSDictionary * _Nullable)extra {
    NSLog(@"monitorEvent - event: %@", event);
    NSLog(@"monitorEvent - data: %@", data);
}

- (void)customReport:(NSString *)eventName url:(NSString *)url bid:(NSString *)bid containerId:(NSString *)containerId category:(NSDictionary *)category metrics:(NSDictionary *)metrics extra:(NSDictionary *)extra sampleLevel:(NSInteger)level
{
    NSLog(@"CustomReport - eventName: %@", eventName);
    NSLog(@"CustomReport - url: %@", url);
    NSLog(@"CustomReport - containerId: %@", containerId);
    NSLog(@"CustomReport - category: %@", category);
    NSLog(@"CustomReport - metrics: %@", metrics);
    NSLog(@"CustomReport - sampleLevel: %ld", (long)level);
}

@end

@implementation IESForestViewController

- (instancetype)init {
    if (self = [super init]) {
        self.customForest = [IESForestKit forestWithBlock:^(IESMutableForestConfig * _Nonnull config) {
//            config.completionQueue = dispatch_get_global_queue(0, 0);
        }];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [IESForestKit setEventMonitor:[CustomMonitor new]];

    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *testCDNFetcherButton = [self buttonWithTitle:@"CDN Fetcher" action:@selector(testCDNFetcher)];
    UIButton *testInvalidCDNFetcherButton = [self buttonWithTitle:@"Invalid CDN URL" action:@selector(testInvalidCDNFetcher)];
    UIButton *testMatchRemoteButton = [self buttonWithTitle:@"Match Remote Settings" action:@selector(testMatchRemoteSetting)];
    UIButton *testMatchNoGecko = [self buttonWithTitle:@"Match Remote But No Gecko" action:@selector(testMatchButNoGecko)];
    UIButton *testBuiltin = [self buttonWithTitle:@"Test Builtin" action:@selector(testBuiltin)];
    UIButton *testCustomFetcherButton = [self buttonWithTitle:@"Test Custom Fetcher" action:@selector(testCustomFetcher)];
    UIButton *testPreload = [self buttonWithTitle:@"Test preload" action:@selector(testPreload)];
    UIButton *testSession= [self buttonWithTitle:@"Test Session" action:@selector(testSession)];
    UIButton *testSession2= [self buttonWithTitle:@"Test Session2" action:@selector(testSession2)];
    UIButton *testIsGeckoResource = [self buttonWithTitle:@"Is Gecko Resource" action:@selector(testIsGeckoResource)];
    UIButton *testCDNMultiVersionParams = [self buttonWithTitle:@"CDN Multi Version Params" action:@selector(testAddCDNMultiVersionParams)];

    self.buttons = @[
        testCDNFetcherButton,
        testInvalidCDNFetcherButton,
        testMatchRemoteButton,
        testMatchNoGecko,
        testBuiltin,
        testCustomFetcherButton,
        testPreload,
        testIsGeckoResource,
        testSession,
        testSession2,
        testCDNMultiVersionParams,
    ];
    
    for (UIButton *button in self.buttons) {
        [self.view addSubview:button];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat buttonWidth = 200.f;
    CGFloat buttonHeight = 44.f;
    CGFloat buttonVerticalMargin = 20.f;
    
    NSInteger buttonCount = self.buttons.count;
    CGFloat buttonOriginX = (CGRectGetWidth(self.view.frame) - buttonWidth) / 2;
    CGFloat buttonOriginY = (CGRectGetHeight(self.view.frame) - buttonCount * buttonHeight - (buttonCount - 1) * buttonVerticalMargin) / 2;
    for (UIButton *button in self.buttons) {
        button.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
        buttonOriginY += (buttonVerticalMargin + buttonHeight);
    }
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action
{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    button.layer.borderWidth = 1.f;
    button.layer.cornerRadius = 4.f;
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    return button;
}

// url 没有 match remote setting
// gecko accessKey, channel, bundle are all nil
- (void)testCDNFetcher
{
//    NSString *urlString = @"https://lf-webcast-sourcecdn-tos.bytegecko.com/obj/byte-gurd-source/webcast/falcon/douyin/wallet_lynx_douyin/pages/wallet_index/template.js";
    NSString *urlString = @"https://lf-webcast-gr-sourcecdn.bytegecko.com/obj/byte-gurd-source-gr/webcast/mono/h5/h5_revenue_red_packet_douyin/douyin/index_mig.html";

    IESForestRequestParameters *params = [IESForestRequestParameters new];
    params.enableMemoryCache = @(YES);
    params.onlyPath = @(YES);

    params.resourceScene = IESForestResourceSceneLynxTemplate;
    NSError *error;
    IESForestResponse* response = [[IESForestKit sharedInstance] fetchResourceSync:urlString parameters:params error:&error];
    if (response) {
        NSLog(@"response.absolutePath: %@", response.absolutePath);
    } else {
        NSLog(@"request failed!");
    }
}

// gecko invalid, buildIn invalid, url is a 404 page
- (void)testInvalidCDNFetcher
{
    NSString *urlString = @"https://lf-dy-gr-sourcecdn.bytegecko.com/obj/byte-gurd-source-gr/online/deploy/demo/only/template.js";

    IESForestRequestParameters *params = [IESForestRequestParameters new];
    params.enableMemoryCache = @(YES);

    id<IESForestResponseProtocol> response = [[IESForestKit sharedInstance] fetchResourceSync:urlString parameters:params];
    if (response) {
        NSLog(@"response.data.length: %ld", response.data.length);
    } else {
        NSLog(@"request failed!");
    }
}

// 满足 gecko 配置， 可以获取到 gecko 文件， 但是 CDN 访问出错
// prefix = /obj/gecko-internal/1324/gecko/resource : AccessKey = 2d15e0aa4fe4a5c91eb47210a6ddf467
// channel: fe_app_react bundle: /imgs/achievement.ab812b69.png
- (void)testMatchRemoteSetting
{
    IESForestRequestParameters *params = [IESForestRequestParameters new];
    params.enableMemoryCache = @(YES);
    params.enableRequestReuse = @(YES);
    NSString *urlString = @"https://tosv.byted.org/obj/gecko-internal/1324/gecko/resource/fe_app_react/imgs/achievement.ab812b69.png";
    [self.customForest fetchResourceAsync:urlString parameters:params completion:^(id<IESForestResponseProtocol>  _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error: %@", [error localizedDescription]);
        } else {
            NSLog(@"response data length %lu", (unsigned long)response.data.length);
        }
    }];
    [self.customForest fetchResourceAsync:urlString parameters:params completion:^(id<IESForestResponseProtocol>  _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error: %@", [error localizedDescription]);
        } else {
            NSLog(@"response data length %lu", (unsigned long)response.data.length);
        }
    }];
}

// prefix: obj/gecko-internal/1324/gecko/resource, AccessKey = 2d15e0aa4fe4a5c91eb47210a6ddf467
// channel: only, bundle:main/template.js
- (void)testMatchButNoGecko
{
//    NSString *urlString = @"https://link.wtturl.cn/?aid=1128&lang=zh&scene=qrcode&jumper_version=1&target=http%3A%2F%2Flf-dy-gr-sourcecdn.bytegecko.com%2Fobj%2Fbyte-gurd-source-gr%2Fwebcast%2Fmono%2Fh5%2Fh5_revenue_red_packet_douyin%2Ftemplate%2Fpages%2Findex.html%3Fweb_bg_color%3D%2523ff161823%26radius%3D8%26background_color%3D161823%26appType%3Ddouyin%26type%3Dpopup%26horizontal_width%3D400%26gravity%3Dbottom%26enableSecLink%3D1%26refer%3Dscan%26height%3D470%26action_source%3D0%26secLinkScene%3Dqrcode";
//    NSString *urlString = @"https://lf-dy-gr-sourcecdn.bytegecko.com/obj/byte-gurd-source-gr/webcast/mono/resource/loader_test/demo/template.js";
    NSString *urlString = @"https://tosv.byted.org/obj/gecko-internal/1324/gecko/resource/only/main/template.js";
    [[IESForestKit sharedInstance] fetchResourceAsync:urlString parameters:nil completion:^(id<IESForestResponseProtocol>  _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error: %@", [error localizedDescription]);
        } else {
            NSLog(@"response data length %lu", (unsigned long)response.data.length);
        }
    }];
}

// url 传递空，通过客户端设置 accessKey, channel, bundle 的方式设置离线资源
// gecko 获取不到，从 builtin 获取到
- (void)testBuiltin
{
    IESForestKit *forest = [IESForestKit sharedInstance];

    IESForestRequestParameters *params = [IESForestRequestParameters new];
    params.accessKey = @"b83d4fe3e39bbb729fcd446a2d21f2c4";
    params.channel = @"avatar_black";
    params.bundle = @"IMG_0870.JPG";
    params.disableGecko = @(YES);
    
    [forest fetchResourceAsync:@"" parameters:params completion:^(id<IESForestResponseProtocol> _Nullable response, NSError * _Nullable error) {
        NSLog(@"");
    }];
}

- (void)testCustomFetcher
{
    id<IESForestInterceptor> interceptor = [CustomInterceptor new];
    [IESForestKit registerGlobalInterceptor:interceptor];
    IESForestRequestParameters *params = [IESForestRequestParameters new];
    NSString *urlString = @"https://lf-dy-gr-sourcecdn.bytegecko.com/obj/byte-gurd-source-gr/10180/gecko/resource/loader_test/template/pages/index/index.html";

    params.enableMemoryCache = @(YES);
    id<IESForestResponseProtocol> response = [[IESForestKit sharedInstance] fetchResourceSync:urlString parameters:params];
    if (response) {
        NSLog(@"response.data.length: %ld", response.data.length);
    } else {
        NSLog(@"request failed!");
    }
    [IESForestKit unregisterGlobalInterceptor:interceptor];
}

/// lock channel in Session
- (void)testSession
{
//    NSString *urlString = @"https://lf-webcast-sourcecdn-tos.bytegecko.com/obj/byte-gurd-source/webcast/falcon/douyin/wallet_lynx_douyin/pages/wallet_index/template.js";
    NSString *urlString = @"https://tosv.byted.org/obj/gecko-internal/1324/gecko/resource/only/main/template.js";

    NSString *sessionId = [[IESForestKit sharedInstance] openSession:nil];
    
    IESForestRequestParameters *params = [IESForestRequestParameters new];
//    params.enableMemoryCache = @(YES);
    params.sessionId = sessionId;
    params.accessKey = @"2d15e0aa4fe4a5c91eb47210a6ddf467";
    params.channel = @"test";
    params.waitGeckoUpdate = @(YES);

    NSURL *url = [NSURL URLWithString:urlString];
    NSArray<NSString *> *pathComponents = [url.path componentsSeparatedByString:@"/"];
    NSString *prefix = [[pathComponents subarrayWithRange:NSMakeRange(0, 6)] componentsJoinedByString:@"/"];
    NSString *channel = [[pathComponents subarrayWithRange:NSMakeRange(6, 1)] componentsJoinedByString:@"/"];
    NSString *bundle = [[pathComponents subarrayWithRange:NSMakeRange(7, pathComponents.count - 7)] componentsJoinedByString:@"/"];
    
    dispatch_queue_t queue = dispatch_queue_create("com.IESForestKit.ForestViewController", DISPATCH_QUEUE_CONCURRENT);
    dispatch_apply(6, queue, ^(size_t index) {
        NSString *tempString = [NSString stringWithFormat:@"%@://%@%@/%@_%@/%@", url.scheme, url.host, prefix, channel, @(index), bundle];
        [[IESForestKit sharedInstance] fetchResourceSync:tempString parameters:params];
        });
    id<IESForestResponseProtocol> response = [[IESForestKit sharedInstance] fetchResourceSync:urlString parameters:params];
    if (response) {
        NSLog(@"[session] response.data.length: %ld", response.data.length);
    } else {
        NSLog(@"[session] request failed!");
    }
    [[IESForestKit sharedInstance] closeSession:sessionId];
}

/// lock channel in Session
- (void)testSession2
{
//    NSString *urlString = @"https://lf-webcast-sourcecdn-tos.bytegecko.com/obj/byte-gurd-source/webcast/falcon/douyin/wallet_lynx_douyin/pages/wallet_index/template.js";
    NSString *urlString = @"https://tosv.byted.org/obj/gecko-internal/1324/gecko/resource/only/main/template.js";

    NSString *sessionId = [[IESForestKit sharedInstance] openSession:nil];
    
    IESForestRequestParameters *params = [IESForestRequestParameters new];
//    params.enableMemoryCache = @(YES);
    params.sessionId = sessionId;
    params.accessKey = @"2d15e0aa4fe4a5c91eb47210a6ddf467";
    params.channel = @"test";
    params.waitGeckoUpdate = @(YES);

    NSURL *url = [NSURL URLWithString:urlString];
    NSArray<NSString *> *pathComponents = [url.path componentsSeparatedByString:@"/"];
    NSString *prefix = [[pathComponents subarrayWithRange:NSMakeRange(0, 6)] componentsJoinedByString:@"/"];
    NSString *channel = [[pathComponents subarrayWithRange:NSMakeRange(6, 1)] componentsJoinedByString:@"/"];
    NSString *bundle = [[pathComponents subarrayWithRange:NSMakeRange(7, pathComponents.count - 7)] componentsJoinedByString:@"/"];
    [[IESForestKit sharedInstance] addChannelToChannelListWithSessionID:sessionId andAccessKey:params.accessKey andChannel:channel];
    
    dispatch_queue_t queue = dispatch_queue_create("com.IESForestKit.ForestViewController", DISPATCH_QUEUE_CONCURRENT);
    dispatch_apply(6, queue, ^(size_t index) {
        NSString *channelString = [NSString stringWithFormat:@"%@%@", channel, @(index)];
        [[IESForestKit sharedInstance] addChannelToChannelListWithSessionID:sessionId andAccessKey:params.accessKey andChannel:channelString];
        });
//    id<IESForestResponseProtocol> response = [[IESForestKit sharedInstance] fetchResourceSync:urlString parameters:params];
//    if (response) {
//        NSLog(@"[session] response.data.length: %ld", response.data.length);
//    } else {
//        NSLog(@"[session] request failed!");
//    }
    BOOL flag = [[IESForestKit sharedInstance] containsChannelInChannelListWithSessionID:sessionId andAccessKey:params.accessKey andChannel:channel];
    [[IESForestKit sharedInstance] closeSession:sessionId];
}

- (void)testPreload
{
    IESForestPreloadConfig *config = [IESForestPreloadConfig new];
    config.mainUrl = @"https://lf-webcast-gr-sourcecdn.bytegecko.com/obj/byte-gurd-source-gr/webcast/mono/h5/h5_revenue_red_packet_douyin/douyin/index_mig.html";
    config.subResources = @{
        @"html": @[@{
            @"url": @"https://www.google.com",
            @"enableMemory": @(YES)
        }, @{
            @"url": @"https://www.examplexxxx.com",
            @"enableMemory": @(YES)
        }],
        @"image": @[@{
            @"url": @"https://tosv.byted.org/obj/gecko-internal/1324/gecko/resource/fe_app_react/imgs/achievement.ab812b69.png",
            @"enableMemory": @(NO)
        }, @{
            @"url": @"https://static.runoob.com/images/demo/demo1.jpg",
            @"enableMemory": @(YES)
        }]
    };

    IESForestRequestParameters *params = [IESForestRequestParameters new];
    params.customParameters = @{ @"rl_container_uuid": @"aaaaaabbbbb"};

    [self.customForest preload:config parameters:params];

    IESForestRequestParameters *normalParams = [IESForestRequestParameters new];
    normalParams.enableRequestReuse = @(YES);
    [self.customForest fetchResourceAsync:@"https://www.google.com" parameters:normalParams completion:^(IESForestResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"--");
    }];


//    NSLog(@"common params: %@", [IESForestKit cdnMultiVersionCommonParameters]);
//    NSString * url = @"https://abc?a=1";
//    NSLog(@"url after: %@", [IESForestKit addCommonParamsForCDNMultiVersionURLString:url]);
//
//    NSString * url2 = @"https://lf-webcast-gr-sourcecdn.bytegecko.com/obj/byte-gurd-source-gr/webcast/mono/h5/h5_revenue_red_packet_douyin/douyin/index_mig.html";
//    NSLog(@"url after: %@", [IESForestKit addCommonParamsForCDNMultiVersionURLString:url2]);
//
//    NSString * url3 = @"https://lf-webcast-gr-sourcecdn.bytegecko.com/obj/byte-gurd-source-gr/webcast/mono/h5/h5_revenue_red_packet_douyin/douyin/index_mig.html?a=1";
//    NSLog(@"url after: %@", [IESForestKit addCommonParamsForCDNMultiVersionURLString:url3]);
}

- (void)testIsGeckoResource
{
    NSString *urlString = @"https://tosv.byted.org/obj/gecko-internal/1324/gecko/resource/fe_app_react/imgs/achievement.ab812b69.png";
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970] * 1000;
//    BOOL flag = [IESForestKit isGeckoResource:urlString];
//    NSString *path = [IESForestKit geckoResourcePathForURLString:urlString];
//    NSLog(@"is gecko resource exist: %@ and path is: %@", @(flag), path);
    for (int i = 0; i < 1000; ++i) {
        [self.customForest fetchLocalResourceSync: urlString skipMonitor:YES];
    }

    NSTimeInterval end = [[NSDate date] timeIntervalSince1970] * 1000;
    NSLog(@"xrc -- fetch 1000 times: average duration is: %lf", (end - start) / 1000);
}

- (void)testAddCDNMultiVersionParams
{
    NSString *nonMultiVersionUrl = @"https://tosv.byted.org/obj/gecko-internal/1324/gecko/resource/fe_app_react/imgs/achievement.ab812b69.png";
    NSString *multiVersionUrl = @"https://lf-webcast-gr-sourcecdn.bytegecko.com/obj/byte-gurd-source-gr/webcast/mono/h5/h5_revenue_red_packet_douyin/douyin/index_mig.html";
    NSString *newMultiVersionUrl = [IESForestKit addCommonParamsForCDNMultiVersionURLString:multiVersionUrl];
    NSLog(@"CDN Multi Version url: %@", newMultiVersionUrl);
    NSString *newNonMultiVersionUrl = [IESForestKit addCommonParamsForCDNMultiVersionURLString:nonMultiVersionUrl];
    NSLog(@"NON CDN Multi Version url: %@", newNonMultiVersionUrl);
}

@end
