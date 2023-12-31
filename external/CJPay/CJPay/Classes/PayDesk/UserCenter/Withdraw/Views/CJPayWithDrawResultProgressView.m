//
//  CJWithdrawResultProgressView.m
//  CJPay
//
//  Created by liyu on 2019/10/11.
//

#import "CJPayWithDrawResultProgressView.h"
#import "CJPayUIMacro.h"
#import "CJPayWithDrawResultProgressCell.h"
#import "CJPayLineUtil.h"
#import "UIView+CJTheme.h"

@interface CJPayWithDrawResultProgressView () <UITableViewDataSource>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIView *sepView;

@end

@implementation CJPayWithDrawResultProgressView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.titleLabel.textColor = localTheme.withdrawResultBottomTitleTextColor;
        self.sepView.backgroundColor = localTheme.withdrawHeaderViewBottomLineColor;
    }
}

//#pragma mark - Views

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _titleLabel.font = [UIFont cj_boldFontOfSize:13];
        _titleLabel.text = CJPayLocalizedStr(@"处理进度");
    }
    return _titleLabel;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.dataSource = self;
        _tableView.allowsSelection = NO;
        _tableView.bounces = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.estimatedRowHeight = 88;
        [_tableView registerClass:CJPayWithDrawResultProgressCell.class forCellReuseIdentifier:CJPayWithDrawResultProgressCell.identifier];
        _tableView.backgroundColor = [UIColor clearColor];
    }
    return _tableView;
}
#pragma mark - Private

- (void)p_setupUI {
    
    [self addSubview:self.tableView];
    CJPayMasMaker(self.tableView, {
        make.top.equalTo(self).offset(16);
        make.left.right.equalTo(self);
        make.height.mas_equalTo([CJPayWithDrawResultProgressCell cellHeight] * 3);
        make.bottom.equalTo(self).offset(-6);
    });
    
    [self addSubview:self.titleLabel];
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self).offset(13);
        make.left.equalTo(self).offset(16);
        make.height.mas_equalTo(18);
    });
    
   self.sepView = [CJPayLineUtil addBottomLineToView:self marginLeft:16 marginRight:16 marginBottom:0];
}

#pragma mark - UITableViewDataSource


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    CJPayWithDrawResultProgressCell *cell = [tableView dequeueReusableCellWithIdentifier:CJPayWithDrawResultProgressCell.identifier];
    CJPayWithDrawResultProgressItem *item = self.items[indexPath.row];
    [cell updateWithItem:item];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items count];
}

#pragma mark - Update

- (void)setItems:(NSArray<CJPayWithDrawResultProgressItem *> *)items {
    if ([_items isEqualToArray:items]) {
        return;
    }
    
    _items = items;
    [self.tableView reloadData];
}

@end
