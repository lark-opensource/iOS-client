//
//  BitableBridge.m
//  BitableBridge
//
//  Created by zenghao on 2018/9/12.
//

#import "BitableBridge.h"
#import <React/RCTBridge.h>
#import <React/RCTLog.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTBundleURLProvider.h>

#import "BTJsToNativeBridge.h"
#import "BTNativeToJsBridge.h"

NSString *const kBitableBridgeErrorDomain = @"com.bytedacne.docs.bitablebridge";


@interface BitableBridge () <RCTBridgeDelegate, JsToNativeBridgeDelegate>

@property (nonatomic, assign) BOOL offlineMode;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *extension;
@property (nonatomic, copy) NSString *remoteIP;
@property (nonatomic, strong) NSURL* jsBundleFolder;

@property (nonatomic, strong) RCTBridge *bridge;

@property (nonatomic, weak) BTJsToNativeBridge *JSBridge;
@property (nonatomic, weak) BTNativeToJsBridge *nativeBridge;

@end

@implementation BitableBridge

- (instancetype)init {
    if (self = [super init]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moduleDidIntialNotification:)
                                                     name:RCTDidInitializeModuleNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(failToLoadNotification:)
                                                     name:RCTJavaScriptDidFailToLoadNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didLoadNotification:)
                                                     name:RCTJavaScriptDidLoadNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)reloadWithOfflineMode:(BOOL)offlineMode
           WithJSBundleFolder:(NSURL *)jsBundleFolder
                     filename:(NSString *)filename
                    extension:(NSString *)extension
                     remoteIP:(NSString *)remoteIP {
    self.offlineMode = offlineMode;
    self.jsBundleFolder = jsBundleFolder;
    self.filename = filename;
    self.extension = extension;
    self.remoteIP = remoteIP;
    
    self.JSBridge = nil;
    self.nativeBridge = nil;
    RCTBridge *lastBridge = self.bridge;
    self.bridge = [[RCTBridge alloc] initWithDelegate:self
                                        launchOptions:nil];
    // 如果bridge刚创建就被invalidate，会中内部断言，所以延迟再invalidate
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [lastBridge invalidate];
     });
}

- (void)executeSourceCode:(NSData *)sourceCode sync:(BOOL)sync {
    [self.bridge executeSourceCode:sourceCode sync:sync];
}

+ (NSURL *)jpodsBundleURL {
    NSBundle *bundle = [NSBundle bundleForClass:self.classForCoder];
    NSURL *bundleURL = [[bundle resourceURL]
                        URLByAppendingPathComponent:@"BitableBridge.bundle"];
    NSBundle *resourceBundle = [NSBundle bundleWithURL:bundleURL];
    
    return [resourceBundle resourceURL];
}

- (void)resetJSBridge {
    [self.bridge invalidate];
    self.bridge = nil;
    self.JSBridge = nil;
    self.nativeBridge = nil;
}

- (void)dealloc {
    RCTLogTrace(@"%@ dealloc", self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self resetJSBridge];
}

- (void)moduleDidIntialNotification:(NSNotification *)notification {
    if (notification.userInfo[@"module"] == nil || notification.userInfo[@"bridge"] == nil) {
        RCTLogWarn(@"invalid module info: %@", notification);
        return;
    }
    
    RCTBridge *targetBridge = (RCTBridge *)notification.userInfo[@"bridge"];
    if (self.bridge != targetBridge) {
        return;
    }
    
    id<RCTBridgeModule> module = (id<RCTBridgeModule>)notification.userInfo[@"module"];
    if ([module isKindOfClass:[BTJsToNativeBridge class]]) {
        self.JSBridge = module;
        self.JSBridge.delegate = self;
    }

    if ([module isKindOfClass:[BTNativeToJsBridge class]]) {
        self.nativeBridge = module;
    }
}

- (void)failToLoadNotification:(NSNotification *)notification {
    if (notification.object == nil || notification.object != self.bridge ) {
        RCTLogWarn(@"invalid failToLoad info: %@", notification);
        return;
    }
    
    NSError *parseError = notification.userInfo[@"error"];
    NSError *error = [NSError errorWithDomain:kBitableBridgeErrorDomain
                                         code:BridgeLoadingErrorJSBundleParseFailed
                                     userInfo:parseError.userInfo];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(loadJSBundleFailedWithError:)]) {
            [self.delegate loadJSBundleFailedWithError:error];
        }
    });
}

- (void)didLoadNotification:(NSNotification *)notification {
    if (notification.object == nil || notification.object != self.bridge ) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(readyToUse)]) {
        // JS端线程还没有初始化完成，需要在主线程发送delegate消息
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate readyToUse];
        });
    }
}

- (void)request:(NSString *)string {
    RCTAssert(self.nativeBridge != nil, @"only can send request after BitableBridge is ready");
    
    [self.nativeBridge request:string];
}

- (void)docsRequest:(NSString *)string {
    RCTAssert(self.nativeBridge != nil, @"only can send request after BitableBridge is ready");
    
    [self.nativeBridge docsRequest:string];
}

#pragma mark - guest host
- (NSString *)guessPackagerHost
{
    static NSString *ipGuess;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *ipPath = [bundle pathForResource:@"ip" ofType:@"txt"];
        ipGuess = [[NSString stringWithContentsOfFile:ipPath encoding:NSUTF8StringEncoding error:nil]
                   stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    });
    
    NSString *host = ipGuess ?: @"localhost";
    return host;
}

- (BOOL)isPackagerRunning:(NSString *)host
{
    NSURL *url = [serverRootWithHost(host) URLByAppendingPathComponent:@"status"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLResponse *response;
    NSData *data = [BitableBridge sendSynchronousRequest:request returningResponse:&response error:NULL];
    NSString *status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [status isEqualToString:@"packager-status:running"];
}


static NSURL *serverRootWithHost(NSString *host)
{
    return [NSURL URLWithString:
            [NSString stringWithFormat:@"http://%@:%lu/",
             host, (unsigned long)kRCTBundleURLProviderDefaultPort]];
}

#pragma mark - Sync Data Task
// https://stackoverflow.com/a/34200617/1921887
+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                 returningResponse:(__autoreleasing NSURLResponse **)responsePtr
                             error:(__autoreleasing NSError **)errorPtr {
    dispatch_semaphore_t    sem;
    __block NSData *        result;
    
    result = nil;
    
    sem = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         if (errorPtr != NULL) {
                                             *errorPtr = error;
                                         }
                                         if (responsePtr != NULL) {
                                             *responsePtr = response;
                                         }
                                         if (error == nil) {
                                             result = data;
                                         }
                                         dispatch_semaphore_signal(sem);
                                     }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}

#pragma mark - RCTBridgeDelegate
- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
    NSURL *jsCodeLocation;
    
    if (self.offlineMode) {
        NSAssert(self.jsBundleFolder != nil, @"jsBundleFolder can not be nil");
        NSAssert(self.filename != nil, @"jsBundleFolder can not be nil");
        NSAssert(self.extension != nil, @"jsBundleFolder can not be nil");
        
        NSURL *fileURL = [[self.jsBundleFolder URLByAppendingPathComponent:self.filename]
                          URLByAppendingPathExtension:self.extension];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
            NSError *error = [NSError errorWithDomain:kBitableBridgeErrorDomain
                                                 code:BridgeLoadingErrorJSBundleNotExisted
                                             userInfo:@{NSLocalizedDescriptionKey: @"file note existed"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(loadJSBundleFailedWithError:)]) {
                    [self.delegate loadJSBundleFailedWithError:error];
                }
            });
        }
        jsCodeLocation = fileURL;
    } else {
        NSAssert(self.filename != nil, @"jsBundleFolder can not be nil");
        
        NSString *host = self.remoteIP;
        if (![self isPackagerRunning:host]) {
            NSError *error = [NSError errorWithDomain:kBitableBridgeErrorDomain
                                                 code:BridgeLoadingErrorPackerServerNotRunning
                                             userInfo:@{NSLocalizedDescriptionKey: @"packer server not runing"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(loadJSBundleFailedWithError:)]) {
                    [self.delegate loadJSBundleFailedWithError:error];
                }
            });
        }
        
        jsCodeLocation = [RCTBundleURLProvider jsBundleURLForBundleRoot:self.filename
                                                           packagerHost:host
                                                              enableDev:YES
                                                     enableMinification:YES];
    }
    
    return jsCodeLocation;
}

#pragma mark - JsToNativeBridgeDelegate
- (void)didReceivedResponse:(NSString *)dataString {
    if ([self.delegate respondsToSelector:@selector(didReceivedResponse:)]) {
        [self.delegate didReceivedResponse:dataString];
    }
}

- (void)didReceivedDocsResponse:(NSString *)jsonString {
    if ([self.delegate respondsToSelector:@selector(didReceivedDocsResponse:)]) {
        [self.delegate didReceivedDocsResponse:jsonString];
    }
}

@end
