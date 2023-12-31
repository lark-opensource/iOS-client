//
//  CJPayNestingLynxCardViewController.m
//  Aweme
//
//  Created by ByteDance on 2023/5/6.
//

#import "CJPayNestingLynxCardViewController.h"
#import "CJPayBaseLynxView.h"
#import "CJPaySettingsManager.h"
#import "CJPayUIMacro.h"

@interface CJPayNestingLynxCardViewController () <CJPayLynxViewDelegate>

@property (nonatomic, copy) NSDictionary *data;
@property (nonatomic, copy) NSString *schema;

@property (nonatomic, strong) CJPayBaseLynxView *lynxCard;
@property (nonatomic, assign) BOOL haveReciveSuccess; // 判断前端发送加载成功事件
@property (nonatomic, assign) BOOL haveShowError; // 如果资源加载错误，存在回调错误，以及前端无返回两种情况。所以这里做一个标志位来避免调用两次p_handleOpenError

@end

@implementation CJPayNestingLynxCardViewController

- (instancetype)initWithSchema:(NSString *)schema data:(NSDictionary *)data {
    self = [super init];
    if (self) {
        self.data = data;
        self.schema = schema;
        self.haveReciveSuccess = NO;
        self.haveShowError = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_judgeOpenStatus];
    [self setupUI];
}

- (void)p_judgeOpenStatus {
    NSInteger timeMS = [CJPaySettingsManager shared].currentSettings.lynxSchemaConfig.keepDialogStandardNew.fallbackWaitTimeMillis;
    NSTimeInterval timeS;
    if ([self p_conformTimeInterval:timeMS]) {
        timeS = ((NSTimeInterval)timeMS)/1000;
    } else {
        timeS = 3.0;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeS * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self p_handleOpenError];
    });
}

- (BOOL)p_conformTimeInterval:(NSInteger)timeMS {
    return timeMS >= 1000 && timeMS <= 6000;
}

- (void)setupUI {
    self.navigationBar.hidden = YES;
    self.view.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.lynxCard];
    
    [self.lynxCard reload];
}

#pragma mark - CJPayLynxViewDelegate

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
        //做安全逻辑，如果前端成功返回了load_success则不返回
        self.haveReciveSuccess = YES;
        CJ_CALL_BLOCK(self.eventBlock, YES, @{});
    } else {
        [self dismissViewControllerAnimated:NO completion:^{}];
    }
        
}

#pragma mark - private func

- (BOOL)cjNeedAnimation {
    return NO;
}

- (BOOL)cjShouldShowBottomView {
    return YES;
}

- (void)p_handleOpenError {
    if (!self.haveShowError && !self.haveReciveSuccess) {
        self.haveShowError = YES;
        [self dismissViewControllerAnimated:NO completion:^{
            CJ_CALL_BLOCK(self.eventBlock, NO, @{});
            CJPayLogInfo(@"未正确拉起lynx挽留弹窗")
        }];
    }
}

- (CJPayBaseLynxView *)lynxCard {
    if (!_lynxCard) {
        _lynxCard = [[CJPayBaseLynxView alloc] initWithFrame:CGRectMake(0, 0, CJ_SCREEN_WIDTH, CJ_SCREEN_HEIGHT) scheme:CJString(self.schema) initDataStr:[self.data cj_toStr]];
        _lynxCard.delegate = self;
    }
    return _lynxCard;
}



@end
