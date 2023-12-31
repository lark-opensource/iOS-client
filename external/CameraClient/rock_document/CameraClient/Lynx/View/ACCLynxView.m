//
//  ACCLynxView.m
//  AWEStudioService-Pods-Aweme
//
//  Created by wanghongyu on 2021/9/9.
//

#import "ACCLynxView.h"
#import <BDXServiceCenter/BDXViewContainerProtocol.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXServiceCenter/BDXLynxKitProtocol.h>
#import <Lynx/BDLynxBridge.h>

#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface ACCLynxView() <BDXKitViewLifecycleProtocol>

@property (nonatomic, strong, readwrite) UIView<BDXLynxViewProtocol> *lynxView;

@property (nonatomic, strong, readwrite) NSURL *currentURL;

@property (nonatomic, copy, readwrite) NSDictionary *props;

@property (nonatomic, copy) NSArray<BDXBridgeMethod *> *xbridges;

@property (nonatomic, strong) id <ACCLynxViewConfigProtocol> config;

@end

@implementation ACCLynxView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.lynxView];
        ACCMasMaker(self.lynxView, {
            make.edges.equalTo(self);
        });
    }
    return self;
}

#pragma mark - public methods

- (void)loadURL:(nonnull NSURL *)url
      withProps:(nullable NSDictionary * )props
       xbridges:(nullable NSArray<BDXBridgeMethod *> *)xbridges
         config:(nonnull id<ACCLynxViewConfigProtocol>)config {
    if (!url || ACC_isEmptyString(url.absoluteString)) {
        NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:-999 userInfo:@{NSLocalizedDescriptionKey:@"URL is empty"}];
        [self loadFailedWithURL: url ? url.absoluteString : @"" error:err];
        return;
    }
    self.currentURL = url;
    self.props = props;
    self.config = config;
    self.xbridges = xbridges;
    
    [self registerLynxComponet];
    [self registerXBridges];
    [self registerContextAndReload];
}

- (void)registerLynxComponet {
    NSDictionary<NSString*, Class>* lynxComponent = self.config.lynxComponet;
    for (NSString *name in lynxComponent.allKeys) {
        [self.lynxView registerUI:lynxComponent[name] withName:name];
    }
}

- (void)registerXBridges {
    [self.lynxView registerXBridgeMethodInstance:self.xbridges];
}

- (void)registerContextAndReload {
    BDXContext *context = [self context];
    context.originURL = self.currentURL.absoluteString;
    [self.lynxView.params.context mergeContext:context];
    [self.lynxView reloadWithContext:context];
}

- (void)updateProps:(NSDictionary *)props {
    self.props = props;
    
    LynxTemplateData *globalProps = [[LynxTemplateData alloc] initWithDictionary:[self lynxParams]];
    [self.lynxView updateData:globalProps processorName:nil];
}

- (void)reloadProps:(NSDictionary *)props {
    self.props = props;
    
    BDXContext *newContext = [self context];
    [self.lynxView.params.context mergeContext:newContext];
    [self.lynxView reloadWithContext:self.lynxView.params.context];
}

- (void)sendEvent:(NSString *)event params:(nullable NSDictionary *)params {
    if (ACC_isEmptyString(event)) {
        NSAssert(NO, @"event name is invalid");
        return;
    }
    [self.lynxView sendEvent:event params:params];
}

#pragma mark - private methods

- (BDXContext *)context {
    BDXContext *context = [BDXContext new];
    // 注入初始数据
    context.initialData = [self lynxParams];
    context.accessKey = [self.config accessKey];
    context.aid = @"1288";
    return context;
}

- (NSDictionary *)lynxParams {
    if (!self.props) {
        return @{};
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([self.props isKindOfClass:[NSDictionary class]]) {
        [params addEntriesFromDictionary:self.props];
    }
    return [params copy];
}

#pragma mark - getter

- (UIView<BDXLynxViewProtocol> *)lynxView {
    if (!_lynxView) {
        id<BDXLynxKitProtocol> lynxKitService = BDXSERVICE(BDXLynxKitProtocol, nil);
        BDXLynxKitParams *params = [[BDXLynxKitParams alloc] init];
        params.widthMode = BDXLynxViewSizeModeExact;
        params.heightMode = BDXLynxViewSizeModeExact;
        _lynxView = (UIView<BDXLynxViewProtocol> *)[lynxKitService createViewWithFrame:CGRectZero params:params];
        _lynxView.lifecycleDelegate = self;
        _lynxView.clipsToBounds = YES;
    }
    return  _lynxView;
}

#pragma mark - HybridContainerLifeCycleProtocol

- (void)view:(id<BDXKitViewProtocol>)view didChangeIntrinsicContentSize:(CGSize)size {
    if ([self.lifeCycleDelegate respondsToSelector:@selector(containerViewDidChangeIntrinsicContentSize:)]) {
        [self.lifeCycleDelegate containerViewDidChangeIntrinsicContentSize:size];
    }
}

- (void)viewWillStartLoading:(id<BDXKitViewProtocol>)view {
    if ([self.lifeCycleDelegate respondsToSelector:@selector(containerViewWillStartLoading)]) {
        [self.lifeCycleDelegate containerViewWillStartLoading];
    }
}

- (void)viewDidStartLoading:(id<BDXKitViewProtocol>)view {
    if ([self.lifeCycleDelegate respondsToSelector:@selector(containerViewDidStartLoading)]) {
        [self.lifeCycleDelegate containerViewDidStartLoading];
    }
}

- (void)view:(id<BDXKitViewProtocol>)view didStartFetchResourceWithURL:(NSString *_Nullable)url {
    if ([self.lifeCycleDelegate respondsToSelector:@selector(containerViewDidFetchResourceWithURL:)]) {
        [self.lifeCycleDelegate containerViewDidFetchResourceWithURL:url];
    }
}

- (void)view:(id<BDXKitViewProtocol>)view didFetchedResource:(nullable id<BDXResourceProtocol>)resource error:(nullable NSError *)error {
    if ([self.lifeCycleDelegate respondsToSelector:@selector(containerViewDidFetchedResourceWithURL:error:)]) {
        [self.lifeCycleDelegate containerViewDidFetchedResourceWithURL:resource.sourceUrl error:error];
    }
}

- (void)viewDidFirstScreen:(id<BDXKitViewProtocol>)view {
    if ([self.lifeCycleDelegate respondsToSelector:@selector(containerViewDidFirstScreen)]) {
        [self.lifeCycleDelegate containerViewDidFirstScreen];
    }
}

- (void)view:(id<BDXKitViewProtocol>)view didFinishLoadWithURL:(NSString *_Nullable)url {
    if ([self.lifeCycleDelegate respondsToSelector:@selector(containerViewDidFinishLoadWithURL:)]) {
        [self.lifeCycleDelegate containerViewDidFinishLoadWithURL:url];
    }
}

- (void)view:(id<BDXKitViewProtocol>)view didLoadFailedWithUrl:(NSString *_Nullable)url error:(nullable NSError *)error {
    [self loadFailedWithURL:url error:error];
}

- (void)viewDidUpdate:(id<BDXKitViewProtocol>)view {
    if ([self.lifeCycleDelegate respondsToSelector:@selector(containerViewDidUpdate)]) {
        [self.lifeCycleDelegate containerViewDidUpdate];
    }
}

- (void)view:(id<BDXKitViewProtocol>)view didRecieveError:(NSError *_Nullable)error {
    if ([self.lifeCycleDelegate respondsToSelector:@selector(containerViewDidReceiveError:)]) {
        [self.lifeCycleDelegate containerViewDidReceiveError:error];
    }
}

- (void)view:(id<BDXKitViewProtocol>)view didReceivePerformance:(NSDictionary *)perfDict {
    if ([self.lifeCycleDelegate respondsToSelector:@selector(containerViewDidReceivePerformance:)]) {
        [self.lifeCycleDelegate containerViewDidReceivePerformance:perfDict];
    }
}

- (void)loadFailedWithURL:(NSString *)urlString error:(NSError *)error {
    if ([self.lifeCycleDelegate respondsToSelector:@selector(containerViewDidLoadFailedWithURL:error:)]) {
        [self.lifeCycleDelegate containerViewDidLoadFailedWithURL:urlString error:error];
    }
}

@end
