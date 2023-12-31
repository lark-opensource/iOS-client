//
// Created by 张海阳 on 2020/3/11.
//

#import "CJPayRechargeResultPayInfoView.h"
#import "CJPayLineUtil.h"
#import "CJPayUIMacro.h"
#import <BDWebImage/BDWebImage.h>
#import "UIView+CJTheme.h"
#import "CJPayUserCenter.h"

@implementation CJPayInvestResultPayInfoViewRowData

- (instancetype)init {
    self = [super init];
    if (self) {
        _font = [UIFont cj_fontOfSize:14];
    }
    return self;
}

- (CGFloat)rowHeight {
    // CJPayInvestResultPayInfoCell
    CGFloat width = CJ_SCREEN_WIDTH - 112 - 16;
    if (!self.buttonAction) {
        return [self.detail cj_sizeWithFont:self.font width:width].height;
    }
    
    // BDPayInvestResultPayInfoWithButtonCell
    NSInteger spacing = 8;
    return [self detailRectSize].height + CJPayInvestResultPayInfoCell.safeDistance * 2 + spacing;
}

- (CGSize)detailRectSize {
    CGFloat titleWidth = [self.title cj_sizeWithFont:self.font width:CJ_SCREEN_WIDTH - 16].width;
    CGFloat buttonWidth = [self.buttonTitle cj_sizeWithFont:self.font width:CJ_SCREEN_WIDTH - 16].width;
    CGSize detailRectSize = [self.detail cj_sizeWithFont:self.font width:CJ_SCREEN_WIDTH - titleWidth - buttonWidth - 16 * 2 - 8 - [self p_safeDistance]];
    return detailRectSize;
}

- (CGFloat)p_safeDistance {
    return (self.font.lineHeight - self.font.pointSize) / 2;
}

@end


@interface CJPayInvestResultPayInfoCell ()

@property (nonatomic, assign, class) CGFloat minHeight;
@property (nonatomic, assign, class) CGFloat safeDistance;
@property (nonatomic, strong, class) UIFont *font;
@property (nonatomic, strong) CJPayInvestResultPayInfoViewRowData *rowData;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *iconImageView;

@end


@implementation CJPayInvestResultPayInfoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self p_setupUI];
        [self p_makeConstraints];
    }
    return self;
}

- (void)configWith:(CJPayInvestResultPayInfoViewRowData *)rowData {
    self.rowData = rowData;
    self.titleLabel.text = rowData.title;
    self.detailLabel.text = rowData.detail;
    self.iconImageView.hidden = !Check_ValidString(rowData.iconUrlStr);
    if (Check_ValidString(rowData.iconUrlStr)) {
        [self.iconImageView cj_setImageWithURL:[NSURL URLWithString:rowData.iconUrlStr]];
    }
}

- (void)p_setupUI {
    self.iconImageView.hidden = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contentView.backgroundColor = [UIColor clearColor];
    self.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.detailLabel];
    [self.contentView addSubview:self.iconImageView];
}

- (void)p_makeConstraints {
    CJPayMasMaker(self.titleLabel, {
        make.leading.equalTo(self.titleLabel.superview).offset(16);
        make.top.equalTo(self.titleLabel.superview).offset(10 - CJPayInvestResultPayInfoCell.safeDistance);
    });
    
    CJPayMasMaker(self.detailLabel, {
        make.left.mas_greaterThanOrEqualTo(self.contentView).offset(100);
        make.right.equalTo(self.contentView).offset(-16);
        make.centerY.equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.iconImageView, {
        make.left.mas_greaterThanOrEqualTo(self.titleLabel.mas_right).offset(8);
        make.centerY.equalTo(self.contentView);
        make.width.height.mas_equalTo(14);
        make.right.equalTo(self.detailLabel.mas_left).offset(-4);
    });
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.titleLabel.textColor = localTheme.rechargeTitleTextColor;
        self.detailLabel.textColor = localTheme.rechargeContentTextColor;
    }
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:13];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
    }
    return _titleLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [UILabel new];
        _detailLabel.font = [UIFont cj_fontOfSize:13];
        _detailLabel.textColor = [UIColor cj_161823ff];
        _detailLabel.textAlignment = NSTextAlignmentRight;
        _detailLabel.numberOfLines = 0;
    }
    return _detailLabel;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
    }
    return _iconImageView;
}

+ (CGFloat)minHeight {
    return 14 + 18;
}

+ (CGFloat)safeDistance {
    return (self.font.lineHeight - self.font.pointSize) / 2;
}

+ (UIFont *)font {
    return [UIFont cj_fontOfSize:14];
}

@end


@interface CJPayInvestResultPayInfoWithButtonCell ()

@property (nonatomic, strong) CJPayButton *actionButton;

@end

@implementation CJPayInvestResultPayInfoWithButtonCell

- (void)configWith:(CJPayInvestResultPayInfoViewRowData *)rowData {
    [super configWith:rowData];
    [self.actionButton setTitle:CJString(rowData.buttonTitle)
                       forState:UIControlStateNormal];
    
    CJPayMasUpdate(self.detailLabel, {
        make.width.mas_equalTo([rowData detailRectSize].width);
    });
}

- (void)p_setupUI {
    [super p_setupUI];
    [self.contentView addSubview:self.actionButton];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        [self.actionButton setTitleColor:localTheme.rechargeCopyButtonColor
                                forState:UIControlStateNormal];
    }
}

- (void)p_makeConstraints {
    [super p_makeConstraints];
    [self.actionButton setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    CJPayMasMaker(self.actionButton, {
        make.trailing.equalTo(self.actionButton.superview).offset(-16);
        make.centerY.equalTo(self.titleLabel);
    });
    
    CJPayMasReMaker(self.detailLabel, {
        make.leading.equalTo(self.titleLabel.mas_trailing).offset(CJPayInvestResultPayInfoCell.safeDistance);
        make.trailing.equalTo(self.actionButton.mas_leading).offset(-8);
        make.top.equalTo(self.titleLabel);
    });
}

- (CJPayButton *)actionButton {
    if (!_actionButton) {
        _actionButton = [CJPayButton new];
        _actionButton.titleLabel.font = [UIFont cj_fontOfSize:14];
        [_actionButton addTarget:self
                          action:@selector(actionButtonClick)
                forControlEvents:UIControlEventTouchUpInside];
    }
    return _actionButton;
}

- (void)actionButtonClick {
    if (self.rowData.buttonAction) {
        self.rowData.buttonAction(self.rowData);
    }
}

@end


@interface CJPayRechargeResultPayInfoView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSArray<CJPayInvestResultPayInfoViewRowData *> *dataSource;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *heightCache;
@property (nonatomic, assign) CGFloat tableViewHeight;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *topLineView;

@end


@implementation CJPayRechargeResultPayInfoView

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.cj_width, 20 + self.tableViewHeight);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _heightCache = [NSMutableDictionary new];

        [self.tableView registerClass:CJPayInvestResultPayInfoCell.class
               forCellReuseIdentifier:CJPayInvestResultPayInfoCell.description];
        [self.tableView registerClass:CJPayInvestResultPayInfoWithButtonCell.class
               forCellReuseIdentifier:CJPayInvestResultPayInfoWithButtonCell.description];

        [self addSubview:self.tableView];
        CJPayMasMaker(self.tableView, {
            make.edges.mas_equalTo(UIEdgeInsetsMake(10, 0, 10, 0));
        });
    }
    return self;
}

- (void)reloadWith:(NSArray<CJPayInvestResultPayInfoViewRowData *> *)dataSource {
    self.dataSource = dataSource;
    [self p_calcTableViewHeight];
    [self invalidateIntrinsicContentSize];
    [self layoutIfNeeded];
    [self.tableView reloadData];
}

- (void)p_calcTableViewHeight {
    [self.heightCache removeAllObjects];
    self.tableViewHeight = 0;
    [self.dataSource enumerateObjectsUsingBlock:^(CJPayInvestResultPayInfoViewRowData *obj, NSUInteger idx, BOOL *stop) {
        CGFloat rowHeight = MAX(
            obj.rowHeight - CJPayInvestResultPayInfoCell.safeDistance * 2,
            CJPayInvestResultPayInfoCell.minHeight
        );
        [self.heightCache setObject:@(rowHeight) forKey:@(idx)];
        self.tableViewHeight += rowHeight;
    }];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.bounces = NO;
    }
    return _tableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJPayInvestResultPayInfoViewRowData *rowData = [self.dataSource cj_objectAtIndex:indexPath.row];
    if (!rowData) {
        return [UITableViewCell new];
    }

    CJPayInvestResultPayInfoCell *cell;
    if (!rowData.buttonAction) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:CJPayInvestResultPayInfoCell.description
                                                    forIndexPath:indexPath];
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:CJPayInvestResultPayInfoWithButtonCell.description
                                                    forIndexPath:indexPath];
    }
    cell.realHeight = self.heightCache[@(indexPath.row)].floatValue;
    [cell configWith:rowData];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return MAX(self.heightCache[@(indexPath.row)].floatValue, CJPayInvestResultPayInfoCell.minHeight);
}

@end
