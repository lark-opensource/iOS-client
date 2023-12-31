//
//  BDPListPermissionContentView.m
//  Timor
//
//  Created by liuxiangxin on 2019/6/17.
//

#import "BDPListPermissionContentView.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPCheckBox.h>
#import <OPFoundation/BDPStyleCategoryDefine.h>

#import <OPFoundation/UIView+BDPBorders.h>
#import <OPFoundation/UIView+BDPAppearance.h>
#import <OPFoundation/UIFont+BDPExtension.h>
#import <OPFoundation/UIColor+BDPExtension.h>

static const CGFloat kCheckIconWidth = 24.f;
static const CGFloat kCheckIconHeight = 24.f;
static const CGFloat kTitleLabelOffsetLeft = 8.f;
static const CGFloat kTableViewOffsetTop = 31.f;
static const CGFloat kTableViewOffsetBottom = 33.f;
static const CGFloat kTableViewCellHeight = 48.f;
static const CGFloat kBorderWidth = .5f;
static const CGFloat kLandscapeContentViewMaxHeight = 204.f;

static NSString *const kCellIdentifier = @"BDPListPermissionContentViewCell";

typedef void(^CheckBoxTapHandler)(BDPCheckBox *checkbox);

@interface BDPListPermissionContentViewCell : UITableViewCell

@property (nonatomic, strong) BDPCheckBox *checkBox;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *topBorder;
@property (nonatomic, strong) UIView *bottomBorder;
@property (nonatomic, copy) CheckBoxTapHandler handler;

@end

@implementation BDPListPermissionContentViewCell

#pragma mark - init

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - UI

- (void)setupUI
{
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self setupCheckBox];
    [self setupTitleLabel];
    [self setupBorders];
}

- (void)setupCheckBox
{
    BDPCheckBox *checkBox = [BDPCheckBox new];
    [self.contentView addSubview:checkBox];
    self.checkBox = checkBox;
    
    checkBox.layer.masksToBounds = YES;
    checkBox.layer.cornerRadius = checkBox.intrinsicContentSize.width / 2;
    checkBox.bdp_styleCategories = @[BDPStyleCategoryPositive, BDPStyleCategoryNegative];

    [checkBox.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor].active = YES;
    [checkBox.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;
    
    [checkBox sizeToFit];
    
    [checkBox addTarget:self action:@selector(onCheckBoxTap:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupTitleLabel
{
    UILabel *label = [UILabel new];
    [self.contentView addSubview:label];
    self.titleLabel = label;
    
    label.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightMedium size:16.f];
    label.textColor = [UIColor bdp_BlackColor1];

    label.translatesAutoresizingMaskIntoConstraints = NO;
    [label.leftAnchor constraintEqualToAnchor:self.checkBox.rightAnchor constant:kTitleLabelOffsetLeft].active = YES;
    [label.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;
}

- (void)setupBorders
{
    UIView *topBorder = [UIView new];
    [self.contentView addSubview:topBorder];
    self.topBorder = topBorder;
    
    topBorder.backgroundColor = UIColor.bdp_BlackColor7;
    
    topBorder.translatesAutoresizingMaskIntoConstraints = NO;
    [topBorder.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor].active = YES;
    [topBorder.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor].active = YES;
    [topBorder.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
    [topBorder.heightAnchor constraintEqualToConstant:kBorderWidth].active = YES;
    
    UIView *bottomBorder = [UIView new];
    [self.contentView addSubview:bottomBorder];
    self.bottomBorder = bottomBorder;
    
    bottomBorder.backgroundColor = UIColor.bdp_BlackColor7;
    
    bottomBorder.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomBorder.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor].active = YES;
    [bottomBorder.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor].active = YES;
    [bottomBorder.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
    [bottomBorder.heightAnchor constraintEqualToConstant:kBorderWidth].active = YES;
}

#pragma mark - Action

- (void)onCheckBoxTap:(id)sender
{
    if (self.handler) {
        self.handler(self.checkBox);
    }
}

@end

@interface BDPListPermissionContentView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy, readwrite) NSArray<NSString *> *titleList;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *scopeMarks;

@end

@implementation BDPListPermissionContentView

#pragma mark - init

- (instancetype)initWithTitleList:(NSArray<NSString *> *)titleList isNewStyle:(BOOL)enableNewStyle
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _enableNewStyle = _enableNewStyle;
        _titleList = titleList.copy;
        _scopeMarks = [NSMutableArray arrayWithCapacity:titleList.count];
        [self setupScopeMarks];
        [self setupUI];
    }
    return self;
}

#pragma mark - UI

- (void)setupUI
{
    self.backgroundColor = [UIColor clearColor];
    [self setupTableView];
}

- (void)setupTableView
{
    UITableView *tableView = [[UITableView alloc] init];
    [self addSubview:tableView];
    self.tableView = tableView;
    
    [tableView registerClass:BDPListPermissionContentViewCell.class forCellReuseIdentifier:kCellIdentifier];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.scrollEnabled = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [tableView.topAnchor constraintEqualToAnchor:self.topAnchor constant:kTableViewOffsetTop].active = YES;
    [tableView.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
    [tableView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-kTableViewOffsetBottom].active = YES;
    [tableView.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
    tableView.backgroundColor = [UIColor clearColor];
    
    CGFloat cellHeight = [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat contentHeight = cellHeight * [self tableView:self.tableView numberOfRowsInSection:0];
    CGFloat maxHeight = [self maxHeight];
    CGFloat height = MIN(maxHeight, contentHeight);
    tableView.scrollEnabled = contentHeight > maxHeight ? YES : NO;
    [tableView.heightAnchor constraintEqualToConstant:height].active = YES;
}

- (NSInteger)maxHeight
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        return [UIScreen mainScreen].bounds.size.height;
    }
    
    return kLandscapeContentViewMaxHeight - kTableViewOffsetTop - kTableViewOffsetBottom;
}

#pragma mark - Data

- (void)setupScopeMarks
{
    for (NSInteger index = 0; index < self.titleList.count; index++) {
        [self.scopeMarks addObject:@YES];
    }
}

- (NSArray<NSNumber *> *)selectedIndexs
{
    NSMutableArray<NSNumber *> *indexs = [NSMutableArray array];
    [self.scopeMarks enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.boolValue) {
            [indexs addObject:@(idx)];
        }
    }];
    return indexs.copy;
}

- (void)updateScopeMarked:(BOOL)marked forIndex:(NSInteger)index
{
    if (index < 0 || index >= self.scopeMarks.count) {
        return;
    }
    
    self.scopeMarks[index] = @(marked);
    
    // check scope marks if all zero , if all zero , disable confirm button
    if ([self.delegate respondsToSelector:@selector(contentView:didUpdateSelectedIndexes:)]) {
        [self.delegate contentView:self didUpdateSelectedIndexes:self.selectedIndexs];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.scopeMarks.count) {
        BOOL selected = [self.scopeMarks[indexPath.row] boolValue];
        [self updateScopeMarked:!selected forIndex:indexPath.row];
    }
    
    [tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kTableViewCellHeight;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.titleList.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *originCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    BDPListPermissionContentViewCell *cell = (BDPListPermissionContentViewCell *)originCell;
    
    cell.selectionStyle = UITableViewCellSeparatorStyleNone;
    if (indexPath.row < self.scopeMarks.count) {
        if (self.scopeMarks[indexPath.row].boolValue) {
            cell.checkBox.status = BDPCheckBoxStatusSelected;
        } else {
            cell.checkBox.status = BDPCheckBoxStatusUnselected;
        }
    }
    
    cell.bottomBorder.hidden = NO;
    if (indexPath.row == 0) {
        cell.topBorder.hidden = NO;
    } else {
        cell.topBorder.hidden = YES;
    }

    NSString *title = [self.titleList objectAtIndex:indexPath.row];
    cell.titleLabel.text = title;
    
    WeakSelf;
    cell.handler = ^(BDPCheckBox *checkbox) {
        StrongSelfIfNilReturn;
        switch (checkbox.status) {
            case BDPCheckBoxStatusUnselected:
                [self updateScopeMarked:NO forIndex:indexPath.row];
                break;
            case BDPCheckBoxStatusSelected:
                [self updateScopeMarked:YES forIndex:indexPath.row];
                break;
            case BDPCheckBoxStatusDisable:
                break;
        }
    };
    
    return cell;
}


@end
