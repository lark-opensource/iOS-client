//
//  CJPayProtocolListViewController.m
//  CJPay
//
//  Created by 张海阳 on 2019/6/25.
//

#import "CJPayProtocolListViewController.h"

#import "CJPayUIMacro.h"
#import "CJPayTracker.h"
#import "CJProtocolListCell.h"
#import "CJPayProtocolDetailViewController.h"
#import "CJPaySDKDefine.h"
#import "CJPayLineUtil.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"
#import "CJPayQuickPayUserAgreement.h"

@interface CJPayProtocolListViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CJPayStyleButton *nextStepButton;

@end

@implementation CJPayProtocolListViewController

- (CJPayStyleButton *)nextStepButton {
    if (!_nextStepButton) {
        CJPayStyleButton *button = [CJPayStyleButton new];
        _nextStepButton = button;
        [button setTitle:CJPayLocalizedStr(@"同意协议并继续") forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        button.backgroundColor = [UIColor cj_colorWithHexString:@"f85959"];
        button.titleLabel.font = [UIFont cj_fontOfSize:17];
        button.layer.cornerRadius = 5;
    }
    return _nextStepButton;
}

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [UITableView new];
        _tableView = tableView;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [tableView registerClass:CJProtocolListCell.class forCellReuseIdentifier:CJProtocolListCell.description];
    }
    return _tableView;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.animationType = HalfVCEntranceTypeFromRight;
        self.navigationBar.title = CJPayLocalizedStr(@"请阅读以下协议");
        self.isForBindCardService = YES;
        self.isShowTitleNubmer = YES;
    }
    return self;
}

- (instancetype)initWithHeight:(CGFloat)height
{
    self = [self init];
    if (self) {
        self.height = height;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBar.bottomLine.hidden = NO;

    [self.contentView addSubview:self.tableView];

    UIView *buttonView = [UIView new];
    buttonView.backgroundColor = UIColor.whiteColor;
    [self.contentView addSubview:buttonView];

    CJPayMasMaker(buttonView, {
        make.left.right.equalTo(buttonView.superview);
        make.bottom.equalTo(buttonView.superview).offset(CJ_IPhoneX ? -34 : 0);
        make.height.equalTo(@72);
    });

    [self.nextStepButton addTarget:self action:@selector(nextStepButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [buttonView addSubview:self.nextStepButton];
    buttonView.hidden = !self.showContinueButton;

    CJPayMasMaker(self.nextStepButton, {
        make.edges.mas_equalTo(UIEdgeInsetsMake(12, 16, 12, 16));
    });

    CJPayMasMaker(self.tableView, {
        make.left.top.right.equalTo(self.tableView.superview);
        if (self.showContinueButton) {
            make.bottom.equalTo(buttonView.mas_top);
        } else {
            make.bottom.equalTo(self.contentView.mas_bottom).offset(CJ_IPhoneX ? -CJ_TabBarSafeBottomMargin-20 : -20);
        }
    });
}

- (void)nextStepButtonAction {
    [self closeWithAnimation:YES comletion:nil];
    CJ_CALL_BLOCK(self.agreeCompletion);
}

#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userAgreements.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJProtocolListCell *cell = [tableView dequeueReusableCellWithIdentifier:CJProtocolListCell.description
                                                                       forIndexPath:indexPath];

    if (cell) {
        CJPayQuickPayUserAgreement *agreement = [self.userAgreements cj_objectAtIndex:(NSUInteger) indexPath.row];
        cell.title = self.isShowTitleNubmer ? [NSString stringWithFormat:@"《%@》", agreement.title] : CJString(agreement.title);
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CJ_DelayEnableView(self.tableView);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CJPayQuickPayUserAgreement *agreement = [self.userAgreements cj_objectAtIndex:(NSUInteger) indexPath.row];

    if (self.isForBindCardService) {
        [self p_bindCardProtocolListClick:agreement];
    }

    if (self.protocolListClick) {
        self.protocolListClick(indexPath.row);
    }
    
}

- (void)p_bindCardProtocolListClick:(CJPayQuickPayUserAgreement*)agreement {
    CJPayProtocolDetailViewController *vc = [[CJPayProtocolDetailViewController alloc] initWithHeight:[self containerHeight]];

    vc.merchantId = self.merchantId;
    vc.appId = self.appId;
    vc.animationType = HalfVCEntranceTypeNone;
    vc.navTitle = agreement.title;
    vc.url = agreement.contentURL;
    vc.showContinueButton = NO;
    vc.isSupportClickMaskBack = YES;
    vc.isShowTitleNubmer = self.isShowTitleNubmer;
    vc.agreeCompletionBeforeAnimation = ^{
        self.containerView.hidden = YES;
    };
    vc.agreeCompletionAfterAnimation = ^{
        [self closeWithAnimation:NO comletion:nil];
        CJ_CALL_BLOCK(self.agreeCompletion);
    };

    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Getter & Setter
- (CGFloat)containerHeight {
    if (self.height <= CGFLOAT_MIN) {
        return CJ_HALF_SCREEN_HEIGHT_LOW;
    } else {
        return self.height;
    }
}

@end
