//
//  CJPayWithDrawNoticeView.m
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import "CJPayWithDrawNoticeView.h"
#import "CJPayRunlampView.h"
#import "CJPayUIMacro.h"
#import "CJPayProtocolManager.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayLocalThemeStyle.h"
#import "UIView+CJTheme.h"
#import "CJPayUserCenter.h"

@interface CJPayWithDrawNoticeView()

@property (nonatomic, strong) UIImageView *suonaView;
@property (nonatomic, strong) CJPayRunlampView *marqueeView;
@property (nonatomic, copy) NSString *lastNotice;
@property (nonatomic, strong) UILabel *showResponseLabel;

@end

@implementation CJPayWithDrawNoticeView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.suonaView = [UIImageView new];
    [self.suonaView cj_setImage:@"cj_withdraw_notice_icon"];
    self.suonaView.image = [self.suonaView.image imageWithRenderingMode:(UIImageRenderingModeAlwaysTemplate)];
    self.marqueeView = [CJPayRunlampView new];
    self.backgroundColor = [UIColor cj_161823WithAlpha:0.03];
    
    [self addSubview:_suonaView];
    CJPayMasMaker(self.suonaView, {
        make.left.equalTo(self).offset(13);
        make.top.equalTo(self).offset(6);
        make.width.height.mas_equalTo(24);
    })
    
    [self addSubview:self.marqueeView];
    CJPayMasMaker(self.marqueeView, {
        make.left.equalTo(self).offset(45);
        make.top.equalTo(self).offset(9);
        make.right.equalTo(self);
        make.height.mas_equalTo(27);
    });
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.suonaView.tintColor = localTheme.withDrawNoticeViewHornTintColor;
    }
}

-(UILabel*)showResponseLabel {
    if(!_showResponseLabel){
        _showResponseLabel = [UILabel new];
        _showResponseLabel.font = [UIFont cj_fontOfSize:13];
        _showResponseLabel.textColor = [UIColor cj_161823ff];
    }
    return _showResponseLabel;
}

- (void)bindViewModel:(CJPayWithDrawNoticeViewModel *)viewModel {
    CJPayWithDrawNoticeViewModel *vm = (CJPayWithDrawNoticeViewModel *)viewModel;
    if ([vm.response.deskConfig.noticeInfo.notice isEqualToString:self.lastNotice]) {
        return;
    }
    if (vm && vm.response.deskConfig.noticeInfo && Check_ValidString(vm.response.deskConfig.noticeInfo.notice)) {
        self.showResponseLabel.text = ((CJPayWithDrawNoticeViewModel *)viewModel).response.deskConfig.noticeInfo.notice;
        [self.marqueeView startMarqueeWith:self.showResponseLabel];
        self.marqueeView.pointsPerFrame = 0.5;
        self.marqueeView.backgroundColor = [UIColor clearColor];
        self.showResponseLabel.backgroundColor = [UIColor clearColor];
        self.lastNotice = vm.response.deskConfig.noticeInfo.notice;
        [self.suonaView setHidden:NO];
    } else {
        self.lastNotice = @"";
        [self.suonaView setHidden:YES];
    }
}

@end

@implementation CJPayWithDrawNoticeViewModel

- (CGFloat)getViewHeight {
    if (self.response.deskConfig.noticeInfo && Check_ValidString(self.response.deskConfig.noticeInfo.notice)) {
       return 36;
    }else{
        return 0;
    }
    
}

- (Class)viewClass {
    return CJPayWithDrawNoticeView.class;
}

+ (CJPayWithDrawNoticeViewModel *)modelWith:(CJPayBDCreateOrderResponse *)response {
    CJPayWithDrawNoticeViewModel *model = [CJPayWithDrawNoticeViewModel new];
    model.response = response;
    return model;
}

@end
