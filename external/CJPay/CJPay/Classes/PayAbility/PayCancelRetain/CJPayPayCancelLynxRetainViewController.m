//
//  CJPayPayCancelLynxRetainViewController.m
//  CJPaySandBox
//
//  Created by ByteDance on 2023/4/2.
//

#import "CJPayPayCancelLynxRetainViewController.h"
#import "CJPayBaseLynxView.h"
#import "CJPayUIMacro.h"
#import "CJPaySettingsManager.h"
@interface CJPayPayCancelLynxRetainViewController() <CJPayLynxViewDelegate>

@property (nonatomic, copy) NSDictionary *postFEParams;
@property (nonatomic, copy) NSString *schema;

@property (nonatomic, strong) CJPayBaseLynxView *retainCard;
@property (nonatomic, strong) NSTimer *closeTimer;
@property (nonatomic, assign) BOOL haveShowError; // 如果资源加载错误，存在回调错误，以及前端无返回两种情况。所以这里做一个标志位来避免调用两次p_handleOpenError

@end

@implementation CJPayPayCancelLynxRetainViewController

- (instancetype)initWithRetainInfo:(NSDictionary *)postFEParams schema:(NSString *)schema {
    self = [super init];
    if (self) {
        self.postFEParams = postFEParams;
        self.schema = schema;
    }
    return self;
}

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_createCloseTimer];
    [self setupUI];
}

- (void)setupUI {
    self.navigationBar.hidden = YES;
    self.view.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.retainCard];
    
    [self.retainCard reload];
}

#pragma mark - CJPayLynxViewDelegate
- (void)viewDidFinishLoadWithURL:(NSString *)url {
    [CJTracker event:@"wallet_rd_show_lynx_retain" params:@{}];
    
    [self p_showAnimationAction];
}

- (void)viewDidFinishLoadWithError:(NSError *)error {
    [self p_handleOpenError];
}

- (void)viewDidRecieveError:(NSError *)error {
    [self p_handleOpenError];
}

- (void)viewDidLoadFailedWithUrl:(NSString *)url error:(NSError *)error {
    [self p_handleOpenError];
}

- (void)lynxView:(UIView *)lynxView receiveEvent:(NSString *)event withData:(NSDictionary *)data {
    if ([event isEqualToString:@"status_page_load_success"]) {
        //做安全逻辑，如果前端成功返回了load，则关闭计时器，否则 「规定时间」过后会关闭当前页面并回调on_cancel_and_leave方法
        [self p_cancelCloseTimer];
    } else {
        [self dismissViewControllerAnimated:NO completion:^{
            CJ_CALL_BLOCK(self.eventBlock, event, data);
        }];
    }
}

#pragma mark - private func

- (void)p_createCloseTimer {
    NSInteger timeMS = [CJPaySettingsManager shared].currentSettings.lynxSchemaConfig.keepDialogStandardNew.fallbackWaitTimeMillis;
    NSTimeInterval timeS;
    if ([self p_conformTimeInterval:timeMS]) {
        timeS = ((NSTimeInterval)timeMS)/1000;
    } else {
        timeS = 3.0;
    }
    
    self.closeTimer = [NSTimer scheduledTimerWithTimeInterval:timeS target:self selector:@selector(p_handleOpenError) userInfo:nil repeats:NO];
}

- (BOOL)p_conformTimeInterval:(NSInteger)timeMS {
    return timeMS >= 1000 && timeMS <= 6000;
}

- (void)p_cancelCloseTimer {
    if (_closeTimer) {
        [self.closeTimer invalidate];
        self.closeTimer = nil;
    }
}

- (void)p_handleOpenError {
    if (!self.haveShowError) {
        self.haveShowError = YES;
        [self dismissViewControllerAnimated:NO completion:^{
            CJ_CALL_BLOCK(self.eventBlock, @"on_close",@{
                @"open_fail": @(YES),
            });
            CJPayLogInfo(@"未正确拉起lynx挽留弹窗")
        }];
    }
}

- (void)p_showAnimationAction {
    [UIView animateWithDuration:0.25 animations:^{
        self.retainCard.alpha = 1;
    }];
}

- (BOOL)cjNeedAnimation {
    return NO;
}

- (BOOL)cjShouldShowBottomView {
    return YES;
}

#pragma mark - lazy load
- (CJPayBaseLynxView *)retainCard {
    if (!_retainCard) {
        _retainCard = [[CJPayBaseLynxView alloc] initWithFrame:CGRectMake(0, 0, CJ_SCREEN_WIDTH, CJ_SCREEN_HEIGHT) scheme:CJString(self.schema) initDataStr:[self.postFEParams cj_toStr]];
        _retainCard.alpha = 0;
        _retainCard.delegate = self;
    }
    return _retainCard;
}
@end
