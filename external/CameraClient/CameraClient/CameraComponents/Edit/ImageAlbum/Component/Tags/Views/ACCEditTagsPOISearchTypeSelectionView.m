//
//  ACCEditTagsPOISearchTypeSelectionView.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/12.
//

#import "ACCEditTagsPOISearchTypeSelectionView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@implementation ACCEditTagsPOISearchType


@end

@interface ACCEditTagsPOISearchTypeTableViewCell : UITableViewCell
@property (nonatomic, strong) UILabel *searchTypeLabel;
@property (nonatomic, assign) BOOL isCurrentSearchType;
@property (nonatomic, strong) UIImageView *checkIcon;
- (void)updateWithText:(NSString *)text;
+ (NSString *)identifier;
@end

@implementation ACCEditTagsPOISearchTypeTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _searchTypeLabel = [[UILabel alloc] init];
        _searchTypeLabel.font = [ACCFont() systemFontOfSize:15.f];
        _searchTypeLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        [self.contentView addSubview:_searchTypeLabel];
        ACCMasMaker(_searchTypeLabel, {
            make.left.equalTo(self.contentView).offset(16.f);
            make.centerY.equalTo(self.contentView);
        });
        
        _checkIcon = [[UIImageView alloc] init];
        _checkIcon.image = ACCResourceImage(@"icon_edit_tags_poi_check");
        _checkIcon.hidden = YES;
        [self.contentView addSubview:_checkIcon];
        ACCMasMaker(_checkIcon, {
            make.width.height.equalTo(@20);
            make.right.equalTo(self.contentView).offset(-16.f);
            make.centerY.equalTo(self.contentView);
        })
    }
    return self;
}

- (void)updateWithText:(NSString *)text
{
    self.searchTypeLabel.text = text;
}

- (void)setIsCurrentSearchType:(BOOL)isCurrentSearchType
{
    _isCurrentSearchType = isCurrentSearchType;
    self.searchTypeLabel.textColor = isCurrentSearchType ? ACCResourceColor(ACCColorConstTextInverse) : ACCResourceColor(ACCColorConstTextInverse4);
    self.checkIcon.hidden = !isCurrentSearchType;
}

+ (NSString *)identifier
{
    return @"ACCEditTagsPOISearchTypeTableViewCell";
}

@end

@interface ACCEditTagsPOISearchTypeSelectionView ()
@property (nonatomic, copy) NSArray<ACCEditTagsPOISearchType *> *dataSource;
@property (nonatomic, strong) CAShapeLayer *maskLayer;
@property (nonatomic, strong) ACCEditTagsPOISearchType *selectedSearchType;
@property (nonatomic, assign) CGFloat topInset;
@property (nonatomic, strong) UIView *topMaskView;
@property (nonatomic, strong) UIView *bottomMaskView;
@end

@implementation ACCEditTagsPOISearchTypeSelectionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _maskLayer = [CAShapeLayer layer];
        
        _tableView = [[UITableView alloc] init];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        [_tableView registerClass:[ACCEditTagsPOISearchTypeTableViewCell class] forCellReuseIdentifier:[ACCEditTagsPOISearchTypeTableViewCell identifier]];
        [self addSubview:_tableView];
        
        _topMaskView = [[UIView alloc] init];
        _topMaskView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapOnTop = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnSafeArea)];
        [_topMaskView addGestureRecognizer:tapOnTop];
        [self addSubview:_topMaskView];
        
        _bottomMaskView = [[UIView alloc] init];
        _bottomMaskView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapOnBottom = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnSafeArea)];
        [_topMaskView addGestureRecognizer:tapOnTop];
        [_bottomMaskView addGestureRecognizer:tapOnBottom];
        [self addSubview:_bottomMaskView];
    }
    return self;
}

- (void)updateWithSearchTypes:(NSArray<ACCEditTagsPOISearchType *> *)searchTypes selectedType:(ACCEditTagsPOISearchType *)selectedType
{
    self.dataSource = searchTypes;
    self.selectedSearchType = selectedType;
    [self.tableView reloadData];
}

- (void)showOnView:(UIView *)view
{
    [self.tableView reloadData];
    [view addSubview:self];
    self.frame = view.bounds;
    CGRect targetFrame = CGRectMake(0, self.topInset, ACC_SCREEN_WIDTH, [self menuHeight]);
    self.tableView.frame = targetFrame;
    self.topMaskView.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, self.topInset);
    self.bottomMaskView.frame = CGRectMake(0, CGRectGetMaxY(self.tableView.frame), ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT - CGRectGetMaxY(self.tableView.frame));
        
    self.maskLayer.frame = self.tableView.bounds;
    CGRect targetPath = self.tableView.bounds;
    self.maskLayer.path = [UIBezierPath bezierPathWithRect:CGRectMake(targetPath.origin.x, targetPath.origin.y, targetPath.size.width, 0)].CGPath;
    self.tableView.layer.mask = self.maskLayer;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.fromValue = (id)self.maskLayer.path;
    animation.toValue = (id)[UIBezierPath bezierPathWithRect:targetPath].CGPath;
    animation.duration = [self animationDuration];
    [self.maskLayer addAnimation:animation forKey:@"path"];
    
    [CATransaction begin];
    self.maskLayer.path = [UIBezierPath bezierPathWithRect:targetPath].CGPath;
    [CATransaction commit];
}

- (void)dismiss
{
    [UIView animateWithDuration:[self animationDuration] animations:^{
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
    CGRect targetPath = self.tableView.bounds;
    targetPath.size.height = 0.f;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.fromValue = (id)self.maskLayer.path;
    animation.toValue = (id)[UIBezierPath bezierPathWithRect:targetPath].CGPath;
    animation.duration = [self animationDuration];
    [self.maskLayer addAnimation:animation forKey:@"path"];
    
    [CATransaction begin];
    self.maskLayer.path = [UIBezierPath bezierPathWithRect:targetPath].CGPath;
    [CATransaction commit];
}

- (NSTimeInterval)animationDuration
{
    return 0.2;
}

- (CGFloat)menuHeight
{
    return [self cellHeight] * [self.dataSource count];
}

- (void)handleTapOnSafeArea
{
    [self dismiss];
    [self.delegate searchTypeSelectionViewWillDismiss:self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource count];;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.dataSource count]) {
        ACCEditTagsPOISearchTypeTableViewCell *cell = (ACCEditTagsPOISearchTypeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[ACCEditTagsPOISearchTypeTableViewCell identifier] forIndexPath:indexPath];
        ACCEditTagsPOISearchType *searchType = self.dataSource[indexPath.row];
        [cell updateWithText:searchType.searchTypeName];
        if (searchType.searchType == self.selectedSearchType.searchType) {
            [cell setIsCurrentSearchType:YES];
        } else {
            [cell setIsCurrentSearchType:NO];
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableviewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.dataSource count]) {
        ACCEditTagsPOISearchType *searchType = self.dataSource[indexPath.row];
        [self.delegate searchTypeSelectionView:self didSelectSearchType:searchType];
    }
    [self dismiss];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellHeight];
}

- (CGFloat)cellHeight
{
    return 52.f;
}

@end
