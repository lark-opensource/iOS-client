//
//  OPNoticeView.m
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/8/5.
//

#import "OPNoticeView.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "OPNoticeMaskView.h"
#import <OPFoundation/BDPI18n.h>
#import <Masonry/Masonry.h>


@interface OPNoticeView()

@property (nonatomic, strong) UIView *noticeView;
@property (nonatomic, strong) OPNoticeMaskView *maskView;
@property (nonatomic,strong,readwrite) OPNoticeModel *model;

@end


@implementation OPNoticeView


-(instancetype)initWithFrame:(CGRect)frame model:(OPNoticeModel *)model isAutoLayout:(BOOL)isAutoLayout{
    self = [super initWithFrame:frame];
    if (self) {
        self.isAutoLayout = isAutoLayout;
        self.model = model;
        [self loadSubview];
    }
    return self;
}

-(void)loadSubview{
    self.noticeView = [self createNoticeViewWithTipInfo:self.model.content url:self.model.link.url];
    if (!self.isAutoLayout) {
    self.op_height = self.noticeView.op_height;
    }
}

-(void)didCloseNoticeView{
    [self.maskView removeFromSuperview];
    [self.noticeView removeFromSuperview];
    if(self.delegate && [self.delegate respondsToSelector:@selector(didCloseNoticeView)]){
        [self.delegate didCloseNoticeView];
    }
}

-(void)showMask{
    if(self.maskView.superview) return ;
    [self.superview addSubview:self.maskView];
    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self);
            make.width.height.equalTo(self.superview);
    }];
    [self.maskView setNoticeText:BDPI18n.SuiteAdminFrontend_Workplace_ContactAdminMsg];
}

-(OPNoticeMaskView *)maskView{
    if (!_maskView) {
        _maskView = [[OPNoticeMaskView alloc] initWithFrame:CGRectZero];
    }
    return _maskView;
}

@end
