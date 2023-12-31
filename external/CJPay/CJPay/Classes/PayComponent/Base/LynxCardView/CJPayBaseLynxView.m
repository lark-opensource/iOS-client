//
//  CJPayBaseLynxView.m
//  Aweme_xiaohong
//
//  Created by wangxiaohong on 2023/2/22.
//

#import "CJPayBaseLynxView.h"

#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayLynxViewPlugin.h"

@interface CJPayBaseLynxView()<CJPayLynxViewDelegate>

@property (nonatomic, strong) UIView *lynxView;
@property (nonatomic, copy) NSString *containerId;

@property (nonatomic, copy) void(^loadCompletion)(BOOL, NSError * _Nullable);

@end

@implementation CJPayBaseLynxView

- (instancetype)initWithFrame:(CGRect)frame scheme:(NSString *)scheme initDataStr:(nonnull NSString *)paramsStr {
    if (CGRectEqualToRect(frame, CGRectZero)) {//判断是否为空区域
        frame = CGRectMake(0, 0, CJ_SCREEN_WIDTH, 0);
    }
    self = [super initWithFrame:frame];
    if (self) {
        _lynxView = [CJ_OBJECT_WITH_PROTOCOL(CJPayLynxViewPlugin) createLynxCardWithScheme:scheme frame:frame initialDataStr:paramsStr delegate:self];
        _containerId = [CJ_OBJECT_WITH_PROTOCOL(CJPayLynxViewPlugin) getContainerIdWithView:_lynxView];
        [self p_setupUI];
    }
    return self;
}

- (void)reload {
    if (!CJ_OBJECT_WITH_PROTOCOL(CJPayLynxViewPlugin)) {
        CJPayLogAssert(YES, @"未引入LynxCard模块");
        if ([self.delegate respondsToSelector:@selector(viewDidFinishLoadWithError:)]) {
            NSError *error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeFail userInfo:@{
                @"errorDesc": @"缺少LynxCard子模块!"
            }];
            [self.delegate viewDidFinishLoadWithError:error];
        }
        return;
    }
    [CJ_OBJECT_WITH_PROTOCOL(CJPayLynxViewPlugin) loadLynxView:self.lynxView];
}

- (NSDictionary *)data {
    NSMutableDictionary *dataDic = [NSMutableDictionary new];
    [dataDic cj_setObject:CJString(self.containerId) forKey:@"containerID"];
    return [dataDic mutableCopy];
}

- (void)p_setupUI{
    [self addSubview:self.lynxView];
    CJPayMasMaker(self.lynxView, {
        make.edges.equalTo(self);
    });
}

- (void)publishEvent:(NSString *)event data:(NSDictionary *)data {
    CJPayLogInfo(@"CJPayLynxView - publishEvent: %@, %@", CJString(event), data ?: @{});
    [CJ_OBJECT_WITH_PROTOCOL(CJPayLynxViewPlugin) publishEvent:event data:data];
}

#pragma mark - CJPayLynxViewDelegate
- (void)lynxView:(UIView *)lynxView receiveEvent:(NSString *)event withData:(NSDictionary *)data {
    CJPayLogInfo(@"CJPayLynxView - receiveEvent: %@, %@", CJString(event), data ?: @{});
    if ([self.delegate respondsToSelector:@selector(lynxView:receiveEvent:withData:)]) {
        [self.delegate lynxView:self receiveEvent:event withData:data];
    }
}

- (void)viewDidConstructJSRuntime {
    [self p_logInfoWithFuncName:NSStringFromSelector(_cmd) params:nil];
    if ([self.delegate respondsToSelector:@selector(viewDidConstructJSRuntime)]) {
        [self.delegate viewDidConstructJSRuntime];
    }
}

- (void)viewWillCreated {
    [self p_logInfoWithFuncName:NSStringFromSelector(_cmd) params:nil];
    if ([self.delegate respondsToSelector:@selector(viewWillCreated)]) {
        [self.delegate viewWillCreated];
    }
}

- (void)viewDidCreated {
    [self p_logInfoWithFuncName:NSStringFromSelector(_cmd) params:nil];
    if ([self.delegate respondsToSelector:@selector(viewDidCreated)]) {
        [self.delegate viewDidCreated];
    }
}

- (void)viewDidChangeIntrinsicContentSize:(CGSize)size {
    [self p_logInfoWithFuncName:NSStringFromSelector(_cmd) params:nil];
    if ([self.delegate respondsToSelector:@selector(viewDidChangeIntrinsicContentSize:)]) {
        [self.delegate viewDidChangeIntrinsicContentSize:size];
    }
}

- (void)viewDidStartLoading {
    [self p_logInfoWithFuncName:NSStringFromSelector(_cmd) params:nil];
    if ([self.delegate respondsToSelector:@selector(viewDidStartLoading)]) {
        [self.delegate viewDidStartLoading];
    }
}

- (void)viewDidFirstScreen {
    [self p_logInfoWithFuncName:NSStringFromSelector(_cmd) params:nil];
    if ([self.delegate respondsToSelector:@selector(viewDidFirstScreen)]) {
        [self.delegate viewDidFirstScreen];
    }
}

- (void)viewDidFinishLoadWithURL:(NSString *_Nullable)url {
    [self p_logInfoWithFuncName:NSStringFromSelector(_cmd) params:@{
        @"url" : CJString(url)
    }];
    if ([self.delegate respondsToSelector:@selector(viewDidFinishLoadWithURL:)]) {
        [self.delegate viewDidFinishLoadWithURL:url];
    }
}

- (void)viewDidUpdate {
    [self p_logInfoWithFuncName:NSStringFromSelector(_cmd) params:nil];
    if ([self.delegate respondsToSelector:@selector(viewDidUpdate)]) {
        [self.delegate viewDidUpdate];
    }
}

- (void)viewDidPageUpdate {
    [self p_logInfoWithFuncName:NSStringFromSelector(_cmd) params:nil];
    if ([self.delegate respondsToSelector:@selector(viewDidPageUpdate)]) {
        [self.delegate viewDidPageUpdate];
    }
}

- (void)viewDidRecieveError:(NSError *_Nullable)error {
    [self p_logInfoWithFuncName:NSStringFromSelector(_cmd) params:@{
        @"error":CJString(error.description)
    }];
    if ([self.delegate respondsToSelector:@selector(viewDidRecieveErrorviewDidStartLoading:)]) {
        [self.delegate viewDidRecieveError:error];
    }
}

- (void)viewDidLoadFailedWithUrl:(NSString *_Nullable)url error:(NSError *_Nullable)error {
    [self p_logInfoWithFuncName:NSStringFromSelector(_cmd) params:@{
        @"url": CJString(url),
        @"error": CJString(error.description)
    }];
    if ([self.delegate respondsToSelector:@selector(viewDidLoadFailedWithUrl:error:)]) {
        [self.delegate viewDidLoadFailedWithUrl:url error:error];
    }
}

- (void)p_logInfoWithFuncName:(NSString *)funcName params:(NSDictionary *)params {
    CJPayLogInfo(@"CJPayLynxView:%@ func:%@ params: %@", NSStringFromClass(self.class) , CJString(funcName), [params cj_toStr]);
}

@end
