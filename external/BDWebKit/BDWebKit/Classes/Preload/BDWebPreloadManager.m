//
//  BDWebPreloadManager.m
//  BDWebKit
//
//  Created by li keliang on 2020/3/9.
//

#import "BDWebPreloadManager.h"
#import <BDWebKit/BDWKPrecreator.h>
#import <ByteDanceKit/ByteDanceKit.h>

@implementation BDWebPreloadResource

+ (instancetype)resourceWithHref:(NSString *)href type:(NSString *)type
{
    BDWebPreloadResource *resource = [BDWebPreloadResource new];
    resource.href = href;
    resource.type = type;
    return resource;
}

@end

@interface BDWebPreloadManager()<WKScriptMessageHandler>

@property (nonatomic) WKWebView    *preloadWebView;
@property (nonatomic) NSMutableDictionary *preloadResources;

@property (nonatomic, strong) NSHashTable *observers;

@end

@implementation BDWebPreloadManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static BDWebPreloadManager *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedManager];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _observers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}

#pragma mark - Public Methods

- (void)addPreloadObserver:(id<BDWebPreloadManagerObserver>)observer
{
    @synchronized (self) {
        [self.observers addObject:observer];
    }
}

- (void)preloadResources:(NSArray<BDWebPreloadResource *> *)resources baseURL:(NSURL *)URL
{
    if (@available(iOS 11.3, *)) {
        
        if (!self.preloadWebView) {
            self.preloadWebView = [[BDWKPrecreator defaultPrecreator] takeWebView];
            self.preloadWebView.hidden = YES;
            
            [self.preloadWebView.configuration.userContentController addScriptMessageHandler:self name:@"preloadOnLoad"];
            [self.preloadWebView.configuration.userContentController addScriptMessageHandler:self name:@"preloadOnError"];
        }
        
        [self stopPreload];
        
        self.preloadResources = [NSMutableDictionary dictionary];
        [resources enumerateObjectsUsingBlock:^(BDWebPreloadResource * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            self.preloadResources[obj.href] = URL;
        }];
        
        NSString *html = [self p_htmlWithPreloadResources:resources];
        [self.preloadWebView loadHTMLString:html baseURL:URL];
    }
}

- (void)stopPreload
{
    [self.preloadWebView stopLoading];
    [[self.preloadResources copy] enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSURL * obj, BOOL * _Nonnull stop) {
        [self p_callingOutLoadFinishHref:key baseURL:obj status:BDWebPreloadStatusCancel];
    }];
}

#pragma mark - Private Methods

- (NSString *)p_htmlWithPreloadResources:(NSArray<BDWebPreloadResource *> *)resources
{
#define stringify(s) #s
    NSMutableString *html = [NSMutableString string];
    [html appendString:@"<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n<meta charset=\"UTF-8\">\n"];
    [html appendString:@stringify(
                                 <script>
                                 function preloadOnLoad(href) {
                                    window.webkit.messageHandlers.preloadOnLoad.postMessage([window.location.href, href])
                                 }
                                  
                                 function preloadOnError(href) {
                                    window.webkit.messageHandlers.preloadOnError.postMessage([window.location.href, href])
                                 }
                                 </script>\n
                                 )];
    
    [resources enumerateObjectsUsingBlock:^(BDWebPreloadResource * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [html appendFormat:@"<link rel=\"preload\" href=\"%@\" as=\"%@\" onload=\"preloadOnLoad(this.href)\" onerror=\"preloadOnError(this.href)\" />\n", obj.href, obj.type];
    }];
    [html appendString:@"</head>\n<body></body>\n</html>"];
    return [html copy];
    
#undef stringify
}

- (void)p_callingOutLoadFinishHref:(NSString *)href baseURL:(NSURL *)baseURL status:(BDWebPreloadStatus)status
{
    @synchronized (self) {
        for (id<BDWebPreloadManagerObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(preloadManager:didFinishPreloadHref:baseURL:status:)]) {
                [observer preloadManager:self didFinishPreloadHref:href baseURL:baseURL status:status];
            }
        }
    }
    
    @synchronized (self.preloadResources) {
        self.preloadResources[href] = nil;
    }
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (![message.body isKindOfClass:NSArray.class]) {
        return;
    }
    
    NSURL *location = [NSURL URLWithString:[(NSArray *)message.body firstObject]];
    NSString *href = [(NSArray *)message.body lastObject];
    
    if ([message.name isEqualToString:@"preloadOnLoad"]) {
        [self p_callingOutLoadFinishHref:href baseURL:location status:BDWebPreloadStatusSucceed];
    }
    else if ([message.name isEqualToString:@"preloadOnError"]) {
        [self p_callingOutLoadFinishHref:href baseURL:location status:BDWebPreloadStatusFailed];
    }
}

@end
