//
//  CJPayHalfPageHybridViewController.m
//  CJPay
//
//  Created by RenTongtong on 2023/7/27.
//


#import "CJPayHalfPageHybridViewController.h"
#import "CJPayBaseLynxView.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayDeskUtil.h"
#import "UIViewController+CJTransition.h"

@interface CJPayHalfPageHybridViewController ()

@property (nonatomic, copy) NSString *schema;
@property (nonatomic, strong) NSDictionary *schemaQuery;
@property (nonatomic, assign) CGFloat contentHeight;

@property (nonatomic, strong) NSDictionary *sdkInfo;

@property (nonatomic, strong) UIView *maskView; // 高度为containerHeight且圆角为8的默认白色的View，用于hybridView没加载之前的动画
@property (nonatomic, strong) CJPayBaseLynxView *hybridView;

@end

@implementation CJPayHalfPageHybridViewController

- (instancetype)initWithSchema:(NSString *)schema sdkInfo:(NSDictionary *)sdkInfo
{
    if (self = [super init]) {
        _schema = schema;
        _sdkInfo = sdkInfo;
        _schemaQuery = [CJPayCommonUtil parseScheme:schema];
        _contentHeight = [_schemaQuery cj_floatValueForKey:kCJPayContentHeightKey];
        self.navigationBar.hidden = YES;
        self.clipToHalfPageBounds = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // self.view、self.containerView 透明
    self.view.backgroundColor = [UIColor clearColor];
    self.containerView.backgroundColor = [UIColor clearColor];

    // 在 containerView 上添加一个 maskView 用于转场动画
    [self.containerView addSubview:self.maskView];
    CJPayMasMaker(self.maskView, {
        make.left.right.top.bottom.equalTo(self.containerView);
    });
    // 在 containerView 上添加一个全屏的 hybridView（containerView的clipToHalfPageBounds NO）
    [self.containerView addSubview:self.hybridView];
    CJPayMasMaker(self.hybridView, {
        make.left.right.bottom.equalTo(self.containerView);
        make.height.equalTo(@(CJ_SCREEN_HEIGHT));
    });

    [self.hybridView reload];
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CJ_SCREEN_WIDTH, [self containerHeight])];
        _maskView.backgroundColor = [UIColor whiteColor];
        [_maskView cj_clipTopCorner:8];
    }
    return _maskView;
}

- (CJPayBaseLynxView *)hybridView {
    if (!_hybridView) {
        _hybridView = [[CJPayBaseLynxView alloc] initWithFrame:CGRectMake(0, 0, CJ_SCREEN_WIDTH, CJ_SCREEN_HEIGHT) scheme:CJString(self.schema) initDataStr:nil];
        _hybridView.delegate = self;
        _hybridView.backgroundColor = [UIColor clearColor];
    }
    return _hybridView;
}

- (CGFloat)containerHeight {
    CGFloat bottom = 0.0;
    if (@available(iOS 11.0, *)) {
        bottom = [UIApplication btd_mainWindow].safeAreaInsets.bottom;
    }
    CGFloat containerHeight = _contentHeight + bottom;
    return containerHeight > CJ_SCREEN_HEIGHT ? CJ_SCREEN_HEIGHT : containerHeight;
}

- (UIColor *)getHalfPageBGColor {
    return [UIColor whiteColor];
}

@end
