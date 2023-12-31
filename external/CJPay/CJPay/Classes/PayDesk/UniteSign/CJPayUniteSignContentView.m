//
//  CJPayUniteSignContentView.m
//  CJPay-9aff3e34
//
//  Created by 王新华 on 2022/9/15.
//

#import "CJPayUniteSignContentView.h"
#import "CJPaySDKMacro.h"
#import "CJPayBytePayMethodView.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayUIMacro.h"

@interface CJPayUniteSignContentView()<CJPayMethodTableViewDelegate>

@property (nonatomic, strong) CJPayBytePayMethodView *tableView;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *currentShowConfig;
@property (nonatomic, copy) NSArray<CJPayDefaultChannelShowConfig *> *datas;

@end

@implementation CJPayUniteSignContentView
@synthesize trackDelegate = _trackDelegate;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_refreshSelectModel {
    NSMutableArray *models = [NSMutableArray new];
    for (CJPayDefaultChannelShowConfig *config in self.datas) {
        CJPayChannelBizModel *bizModel = [config toBizModel];
        [models btd_addObject:bizModel];
        if (self.currentShowConfig && config.type == self.currentShowConfig.type) {
            bizModel.isConfirmed = YES;
        } else {
            bizModel.isConfirmed = NO;
        }
    }
    self.tableView.models = models;
}

- (void)p_setupUI {
    [self addSubview: self.tableView];
    CJPayMasMaker(self.tableView, {
        make.edges.equalTo(self);
    });
}

- (CJPayBytePayMethodView *)tableView {
    if (!_tableView) {
        _tableView = [CJPayBytePayMethodView new];
        _tableView.delegate = self;
    }
    return _tableView;
}

- (void)bindData:(CJPayTypeInfo *)info {
    self.datas = [info showConfigForUniteSign];
    CJPayChannelType curType = self.currentShowConfig ? self.currentShowConfig.type : [CJPayTypeInfo getChannelTypeBy:info.defaultPayChannel]; // 优先根据选中处理，未选中取默认支付方式

    for (CJPayDefaultChannelShowConfig *channel in self.datas) {
        if (curType == channel.type) {
            self.currentShowConfig = channel;
        }
    }
    [self p_refreshSelectModel];
}

- (CJPayDefaultChannelShowConfig *)currentChoosePayMethod {
    return self.currentShowConfig;
}

#pragma - mark tableView delegate
- (void)didSelectAtIndex:(int)selectIndex {
    if (selectIndex >= self.datas.count) {
        CJPayLogAssert(NO, @"selectIndex = %d 不可用或者越界",selectIndex);
        return;
    }
    if (self.datas[selectIndex].payChannel.signStatus != 1) {
        self.currentShowConfig = self.datas[selectIndex];
        [self p_refreshSelectModel];
        [self.trackDelegate event:@"wallet_cashier_choose_method_click" params:@{}];
    }
}

@end
