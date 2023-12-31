//
//  AWEEditStickerBubbleView.m
//  Pods
//
//  Created by 赖霄冰 on 2019/9/3.
//

#import "AWEEditStickerBubbleManager.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

NSString * const ACCStickerEditingBubbleManagerName = @"com.sticker.editing.AWEEditStickerBubbleManager";

NSString * const ACCEditStickerBubbleVisableDidChangedNotify = @"ACCEditStickerBubbleVisableDidChangedNotify";
NSString * const ACCEditStickerBubbleVisableDidChangedNotifyGetNameKey = @"ACCEditStickerBubbleVisableDidChangedNotifyGetNameKey";
NSString * const ACCEditStickerBubbleVisableDidChangedNotifyGetVisableKey = @"ACCEditStickerBubbleVisableDidChangedNotifyGetVisableKey";

// 计算叉积
NS_INLINE CGFloat direct(CGPoint ptA, CGPoint ptB, CGPoint point) {
    return (ptA.x-ptB.x)*(point.y-ptA.y) - (ptA.y-ptB.y)*(point.x-ptA.x);
}

#define f(x) [x floatValue]
static CGFloat const ACCBubbleLimitPadding = 8.f;
static CGFloat const ACCBubbleLimitArrowMargin = 12.f;
static CGFloat const ACCBubbleAnchorPadding = 8.f;
static CGFloat const ACCBubbleArrowHeight = 6.f;
static CGFloat const ACCBubbleCellSepLineHeight = .5f;
static CGFloat const ACCBubbleCellMargin = 12.f;
static CGFloat const ACCBubbleCellImageWidth = 20.f;
static CGFloat const ACCBubbleCellImageTextPadding = 4.f;
static CGFloat const ACCBubbleCellMinWidth = 81.f;
static CGFloat const ACCBubbleCellRowHeight = 44.f;

@interface AWEEditStickerBubbleViewCell : UITableViewCell

@property (nonatomic, strong) AWEEditStickerBubbleItem *bubbleItem;
@property (nonatomic, strong) UIView *sepLine;

- (void)showBubbleShakeAnimation;

+ (NSString *)awe_identifier;

@end

@interface AWEEditStickerBubbleView :UIView <AWEEditStickerBubbleProtocol, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, assign, readonly) CGFloat calcMaxWidth; // O(n) calc property
@property (nonatomic, copy) NSArray<NSNumber *> *transformedRectCornerPoints;
@property (nonatomic, assign) BOOL isUpsideDown;
@property (nonatomic, assign) CGAffineTransform anchorViewTransform;
@property (nonatomic, assign) CGFloat arrowOffset;
// ===============================================
@property (nonatomic, weak) UIView *parentView;
@property (nonatomic, weak) AWEEditStickerBubbleViewCell *shakeAniCell;
@property (nonatomic, assign) CGPoint touchPoint;

@end

@interface AWEEditStickerBubbleView (FixLayout)
- (CGPoint)fixBubbleLocation;
- (NSArray<NSNumber *> *)getTransformedFloatsOfRect:(CGRect)rect transform:(CGAffineTransform)transform;
- (CGPoint)mockAnchorPoint:(CGPoint)point forDirection:(AWEEditStickerBubbleArrowDirection)direction;
@end

@implementation AWEEditStickerBubbleView
@synthesize bubbleItems = _bubbleItems;
@synthesize bubbleVisible = _bubbleVisible;
@synthesize arrowDirection = _arrowDirection;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.tableView];
    [self addSubview:self.arrowImageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.arrowImageView.acc_size = CGSizeMake(12, ACCBubbleArrowHeight);
    CGFloat h = ACCBubbleCellRowHeight * self.bubbleItems.count + ACCBubbleCellSepLineHeight * (self.bubbleItems.count > 0 ? self.bubbleItems.count - 1 : 0) + ACCBubbleArrowHeight;
    self.bounds = CGRectMake(0, 0, self.calcMaxWidth, h);
    CGPoint anchorPoint = [self fixBubbleLocation];
    anchorPoint = [self mockAnchorPoint:anchorPoint forDirection:self.arrowDirection];
    self.acc_centerX = anchorPoint.x;
    CGFloat deltaY = .25;  // 气泡和箭头有时会出现一点间隙，先交叉.5pt解一下
    switch (self.arrowDirection) {
        case AWEEditStickerBubbleArrowDirectionUp: {
            self.acc_bottom = anchorPoint.y;
            self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)-self.arrowImageView.acc_height+deltaY);
            self.arrowImageView.acc_centerX = self.tableView.acc_centerX + self.arrowOffset;
            self.arrowImageView.acc_top = self.tableView.acc_bottom-deltaY;
        }
            break;
        case AWEEditStickerBubbleArrowDirectionDown: {
            self.acc_top = anchorPoint.y;
            self.arrowImageView.acc_top = 0;
            self.tableView.frame = CGRectMake(0, self.arrowImageView.acc_bottom-deltaY, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)-self.arrowImageView.acc_height+deltaY);
            self.arrowImageView.acc_centerX = self.tableView.acc_centerX + self.arrowOffset;
        }
            break;
    }
}

#pragma mark - Public

- (void)setBubbleVisible:(BOOL)bubbleVisible animated:(BOOL)animated {
    BOOL doNotUpdate = !self.bubbleVisible && !bubbleVisible;
    if (doNotUpdate) return;
    self.bubbleVisible = bubbleVisible;
    [self update];
    
    CGFloat alpha = bubbleVisible ? 1 : 0;
    if (animated) {
        // 平移动画
        CGFloat deltaY = self.arrowDirection == AWEEditStickerBubbleArrowDirectionUp ? 8.f : -8.f;
        CGFloat originTop = self.acc_top;
        self.acc_top = bubbleVisible ? originTop + deltaY : originTop;
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:.2 animations:^{
                self.acc_top = bubbleVisible ? originTop : originTop + deltaY;
                self.alpha = alpha;
            } completion:^(BOOL finished) {
                if (bubbleVisible && self.shakeAniCell.bubbleItem.showShakeAnimation) {
                    [self.shakeAniCell showBubbleShakeAnimation];
                }
            }];
        });
    } else {
        self.alpha = alpha;
    }
}

- (void)setRect:(CGRect)rect touchPoint:(CGPoint)touchPoint transform:(CGAffineTransform)transform inParentView:(UIView *)parentView {
    if (!parentView) return;
    // 计算transform后顶点坐标数组
    self.transformedRectCornerPoints = [self getTransformedFloatsOfRect:rect transform:transform];
    
    self.anchorViewTransform = transform;
    self.touchPoint = touchPoint;
    self.arrowDirection = AWEEditStickerBubbleArrowDirectionUp; // 默认箭头朝下
    if (parentView != self.parentView) {
        self.parentView = parentView;
        [self removeFromSuperview];
        [parentView addSubview:self];
    }
}

- (void)update {
    [self.tableView reloadData];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self updateArrowDirection];
}

- (void)updateArrowDirection {
    NSString *imageName = @"icBubbleDownNew";
    if (self.arrowDirection == AWEEditStickerBubbleArrowDirectionDown) {
        imageName = @"icBubbleUpNew";
    }
    [self.arrowImageView setImage:ACCResourceImage(imageName)];
}

#pragma mark - <UITableViewDataSource>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bubbleItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AWEEditStickerBubbleItem *item = self.bubbleItems[indexPath.row];
    AWEEditStickerBubbleViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AWEEditStickerBubbleViewCell.awe_identifier];
    cell.bubbleItem = item;
    cell.sepLine.hidden = (indexPath.row == self.bubbleItems.count-1);
    if (item.showShakeAnimation) {
        self.shakeAniCell = cell;//only one
    }
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AWEEditStickerBubbleItem *item = self.bubbleItems[indexPath.row];
    ACCBLOCK_INVOKE(item.actionBlock);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ACCBubbleCellRowHeight;
}

#pragma mark - getter && setter

- (CGRect)parentViewFrame {
    return self.parentView.bounds;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = ACCResourceColor(ACCUIColorConstSDPrimary);
        _tableView.layer.cornerRadius = 8.f;
        _tableView.layer.masksToBounds = YES;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.scrollEnabled = NO;
        [_tableView registerClass:AWEEditStickerBubbleViewCell.class forCellReuseIdentifier:AWEEditStickerBubbleViewCell.awe_identifier];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        if ([_tableView respondsToSelector:@selector(contentInsetAdjustmentBehavior)]) {
            if (@available(iOS 11.0, *)) {
                _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
        }
    }
    return _tableView;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] init];
    }
    return _arrowImageView;
}

- (CGFloat)calcMaxWidth {
    __block CGFloat maxWidth = ACCBubbleCellMinWidth;
    [self.bubbleItems enumerateObjectsUsingBlock:^(AWEEditStickerBubbleItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGSize textSize = [obj.title boundingRectWithSize:CGSizeMake(ACC_SCREEN_WIDTH, 20.f) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[ACCFont() acc_boldSystemFontOfSize:14]} context:nil].size;
        CGFloat contentWidth = ACCBubbleCellMargin * 2 + ACCBubbleCellImageWidth + ACCBubbleCellImageTextPadding + textSize.width;
        maxWidth = MAX(maxWidth, contentWidth);
    }];
    return maxWidth;
}

@end

@implementation AWEEditStickerBubbleView (FixLayout)

- (BOOL)noSpaceLeft {
    NSArray<NSNumber *> *pts = self.transformedRectCornerPoints;
    if (self.transformedRectCornerPoints.count != 8) return NO;
    // 线段AB贴纸上边，线段EF贴纸下边
    CGPoint A = CGPointMake(f(pts[0]), f(pts[1]));
    CGPoint B = CGPointMake(f(pts[2]), f(pts[3]));
    CGPoint E = CGPointMake(f(pts[4]), f(pts[5]));
    CGPoint F = CGPointMake(f(pts[6]), f(pts[7]));
    // CD:x=0 GH:x=width
    CGPoint C = CGPointMake(0, [self parentViewFrame].size.height);
    CGPoint D = CGPointZero;
    CGPoint G = CGPointMake([self parentViewFrame].size.width, [self parentViewFrame].size.height);
    CGPoint H = CGPointMake([self parentViewFrame].size.width, 0);
    // 线段l1l2靠近线段CD, r1r2靠近GH
    CGPoint l1, l2, r1, r2;
    if (ABS((A.x+B.x)/2 - C.x) < ABS((A.x+B.x)/2 - G.x)) {
        l1 = A;
        l2 = B;
        r1 = E;
        r2 = F;
    } else {
        l1 = E;
        l2 = F;
        r1 = A;
        r2 = B;
    }
    CGFloat d1 = direct(C, D, l1);
    CGFloat d2 = direct(C, D, l2);
    CGFloat d3 = direct(l1, l2, C);
    CGFloat d4 = direct(l1, l2, D);
    BOOL rs1 = ((d1*d2>0&&d3*d4>0) && d1>0&&d2>0);
    
    CGFloat d5 = direct(G, H, r1);
    CGFloat d6 = direct(G, H, r2);
    CGFloat d7 = direct(r1, r2, G);
    CGFloat d8 = direct(r1, r2, H);
    BOOL rs2 = ((d5*d6>0&&d7*d8>0) && d5<0&&d6<0);
    // 和前置条件结合，保证贴纸上下边都在左右边界的外边
    return rs1 && rs2;
}

- (BOOL)noEnoughSpaceForRect:(CGRect)rect {
    CGRect parentViewRect = [self parentViewFrame];
    return !CGRectContainsRect(parentViewRect, rect);
}

/**
 - 气泡适配规则
 1、气泡箭头默认处于气泡的中点处，气泡默认从贴纸上侧出现（箭头在下）
 2、当贴纸上方的空间不足以完全展示气泡时，将气泡放在贴纸下方展示（箭头在上）
 - 边界适配规则
 当贴纸不断向屏幕边缘移动时，
 1、保证气泡在贴纸的中点的 上/下方展示，若不满足；
 2、则将气泡整体往屏幕内挪动，气泡边距离屏幕边极限（marigin=8），若仍不满足；
 3、则挪动气泡箭头，箭头距离气泡边界极限margin=12
 4、此为最极限状况，如果贴纸再往边界移动，则保持最极限状态。箭头距离贴纸边距的margin保持8
 - 旋转适配规则
 1、0-90（含90）度，及270-360度时，以贴纸上边中点为锚点对齐气泡，保证该中点距离气泡箭头margin=8
 2、90-270（含270）度时，以贴纸下边中点为锚点对齐气泡，保证该中点距离气泡margin=8
 - 极大适配规则
 1、当贴纸放大至无法在上/下显示气泡时，气泡用箭头在下的样式，点哪出那
 */
- (CGPoint)fixBubbleLocation {
    CGSize bubbleSize = self.bounds.size;
    // 箭头朝下的
    self.arrowDirection = AWEEditStickerBubbleArrowDirectionUp;
    CGPoint point = [self getShowLocation];
    point = [self fixBubbleLocationWithPoint:point];
    CGFloat arrowOffsetForDirectionUp = self.arrowOffset;
    BOOL hasNoSpaceForDirectionUp = [self noEnoughSpaceForRect:CGRectMake(point.x-bubbleSize.width/2, point.y-ACCBubbleAnchorPadding-bubbleSize.height, bubbleSize.width, bubbleSize.height)];
    if ([UIDevice acc_isIPhoneX] || [UIDevice acc_isIPhoneXsMax]){ // 如果是刘海屏就修正安全距离
        hasNoSpaceForDirectionUp = [self noEnoughSpaceForRect:CGRectMake(point.x-bubbleSize.width/2, point.y-ACCBubbleAnchorPadding-bubbleSize.height-35, bubbleSize.width, bubbleSize.height)];
    }
    CGPoint pointForDirectionUp = point;
    BOOL hasNoSpaceForDirectionDown = NO;
    CGPoint pointForDirectionDown = CGPointZero;
    CGFloat arrowOffsetForDirectionDown = 0;
    if (point.y - self.acc_height <= ACCBubbleLimitPadding || hasNoSpaceForDirectionUp) {
        // 箭头朝上的
        self.arrowDirection = AWEEditStickerBubbleArrowDirectionDown;
        point = [self getShowLocation];
        point = [self fixBubbleLocationWithPoint:point];
        arrowOffsetForDirectionDown = self.arrowOffset;
        hasNoSpaceForDirectionDown = [self noEnoughSpaceForRect:CGRectMake(point.x-bubbleSize.width/2, point.y+ACCBubbleAnchorPadding, bubbleSize.width, bubbleSize.height)];
        pointForDirectionDown = point;
    }
    if (!hasNoSpaceForDirectionUp && !hasNoSpaceForDirectionDown && [self noSpaceLeft]) {
        hasNoSpaceForDirectionUp = hasNoSpaceForDirectionDown = YES;
    }
    if (!hasNoSpaceForDirectionUp) {
        self.arrowDirection = AWEEditStickerBubbleArrowDirectionUp;
        self.arrowOffset = arrowOffsetForDirectionUp;
        point = pointForDirectionUp;
    } else if (!hasNoSpaceForDirectionDown) {
        self.arrowDirection = AWEEditStickerBubbleArrowDirectionDown;
        self.arrowOffset = arrowOffsetForDirectionDown;
        point = pointForDirectionDown;
    } else {
        self.arrowDirection = AWEEditStickerBubbleArrowDirectionUp;
        self.arrowOffset = 0.f;
        point = self.touchPoint;
    }
    return point;
}

- (CGPoint)fixBubbleLocationWithPoint:(CGPoint)point {
    point = [self fixBubbleHorizontalLocationWithPoint:point];
    CGFloat angle = atan2(self.anchorViewTransform.b, self.anchorViewTransform.a);
    if (!(ACC_FLOAT_EQUAL_TO(angle, 0) || ACC_FLOAT_EQUAL_TO(ABS(angle), M_PI_2))) { // 没有旋转的不需要修正上下空间了
        CGPoint fixHoriPoint = point;
        point = [self fixBubbleVerticalLocationWithPoint:point];
        if (!CGPointEqualToPoint(fixHoriPoint, point)) { // 上下fix生效了,arrowoffset不再准确
            self.arrowOffset = 0.f;
        }
    }
    return point;
}

- (CGPoint)fixBubbleHorizontalLocationWithPoint:(CGPoint)point {
    CGFloat xOffset = 0.f, yOffset = 0.f, arrowOffset= 0.f;
    CGFloat arrowBubbleInitMargin = self.acc_width/2.f-self.arrowImageView.acc_width/2;
    // 处理左右情况
    CGFloat width = [self getRotateRectWidth];
    if (point.x < ACCBubbleLimitPadding + self.acc_width/2) {
        // 气泡边距离屏幕边极限（marigin=8）
        xOffset = ACCBubbleLimitPadding + self.acc_width/2 - point.x;
        yOffset = [self getRotateYOffsetWith:xOffset];
        if (width/2.f - xOffset < ACCBubbleLimitArrowMargin || xOffset > width/2.f) {
            // 开始挪动气泡箭头的临界条件，箭头离贴纸边距离留个（marigin=12）
            arrowOffset -= ACCBubbleLimitArrowMargin - (width/2.f - xOffset);
            if (arrowBubbleInitMargin + arrowOffset < ACCBubbleLimitArrowMargin) {
                // 到达最极限状况，箭头距离气泡边界极限margin=12
                arrowOffset = ACCBubbleLimitArrowMargin - arrowBubbleInitMargin;
            }
            yOffset = [self getRotateYOffsetWith:width/2.f-ACCBubbleLimitArrowMargin];
        }
    }
    if (self.parentView && [self parentViewFrame].size.width - (point.x + self.acc_width/2) < ACCBubbleLimitPadding) {
        xOffset = [self parentViewFrame].size.width - (point.x + self.acc_width/2) - ACCBubbleLimitPadding;
        yOffset = [self getRotateYOffsetWith:xOffset];
        if (width/2.f + xOffset < ACCBubbleLimitArrowMargin || -xOffset > width/2.f) {
            arrowOffset += ACCBubbleLimitArrowMargin - (width/2.f + xOffset);
            if (arrowBubbleInitMargin - arrowOffset < ACCBubbleLimitArrowMargin) {
                arrowOffset = arrowBubbleInitMargin - ACCBubbleLimitArrowMargin;
            }
            yOffset = [self getRotateYOffsetWith:ACCBubbleLimitArrowMargin-width/2.f];
        }
    }
    point.x += xOffset;
    point.y += yOffset;
    self.arrowOffset = arrowOffset;
    return point;
}

- (CGPoint)fixBubbleVerticalLocationWithPoint:(CGPoint)point {
    // 处理上下放不下的情况
    CGFloat xOffset = 0.f, yOffset = 0.f;
    if (point.y - self.acc_height < ACCBubbleLimitPadding) {
        yOffset = ACCBubbleLimitPadding - point.y + self.acc_height;
        xOffset = [self getRotateXOffsetWith:yOffset];
        NSArray<NSNumber *> *pts = self.transformedRectCornerPoints;
        CGPoint test = point;
        test.x += xOffset;
        test.y += yOffset;
        // 判断某个点是否在线段下面（左手边）
        if (direct(CGPointMake(f(pts[0]),f(pts[1])), CGPointMake(f(pts[2]),f(pts[3])), test) <= 0) {
            xOffset = yOffset = 0.f;
        }
    }
    if (self.parentView && point.y > [self parentViewFrame].size.height - self.acc_height - ACCBubbleLimitPadding) {
        yOffset = [self parentViewFrame].size.height - self.acc_height - ACCBubbleLimitPadding - point.y;
        xOffset = [self getRotateXOffsetWith:yOffset];
    }
    point.x += xOffset;
    point.y += yOffset;
    return point;
}

- (CGPoint)mockAnchorPoint:(CGPoint)point forDirection:(AWEEditStickerBubbleArrowDirection)direction {
    CGFloat angle = atan2(self.anchorViewTransform.b, self.anchorViewTransform.a);
    CGFloat deltaX = ACCBubbleAnchorPadding * (self.isUpsideDown ? sin(angle) : -sin(angle));
    CGFloat deltaY = ACCBubbleAnchorPadding*ABS(cos(angle));
    CGFloat suggestPointX;
    switch (direction) {
        case AWEEditStickerBubbleArrowDirectionUp:
            suggestPointX = point.x-deltaX;
            break;
        case AWEEditStickerBubbleArrowDirectionDown:
            suggestPointX = point.x+deltaX;
            break;
    }
    if (ACC_FLOAT_LESS_THAN((suggestPointX-self.acc_width/2.f), ACCBubbleLimitPadding) ||
        ACC_FLOAT_LESS_THAN([self parentViewFrame].size.width-(suggestPointX+self.acc_width/2.f), ACCBubbleLimitPadding)) {
        deltaX = 0; deltaY = ACCBubbleAnchorPadding;
    }
    switch (direction) {
        case AWEEditStickerBubbleArrowDirectionUp:
        {
            return CGPointMake(point.x-deltaX, point.y-deltaY);
        }
        case AWEEditStickerBubbleArrowDirectionDown:
        {
            return CGPointMake(point.x+deltaX, point.y+deltaY);
        }
    }
}

// 返回视觉上的[左上xy,右上xy，左下xy，右下xy]
- (NSArray<NSNumber *> *)getTransformedFloatsOfRect:(CGRect)rect transform:(CGAffineTransform)transform {
    CGFloat angle = atan2(transform.b, transform.a);
    CGPoint rectCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGRect originRect = CGRectMake(-rect.size.width/2, -rect.size.height/2, rect.size.width, rect.size.height);
    
    CGPoint topLeft = originRect.origin;
    topLeft = CGPointApplyAffineTransform(topLeft, transform);
    topLeft.x += rectCenter.x;
    topLeft.y += rectCenter.y;
    
    CGPoint topRight = originRect.origin;
    topRight.x += originRect.size.width;
    topRight = CGPointApplyAffineTransform(topRight, transform);
    topRight.x += rectCenter.x;
    topRight.y += rectCenter.y;
    
    CGPoint botLeft = originRect.origin;
    botLeft.y += originRect.size.height;
    botLeft = CGPointApplyAffineTransform(botLeft, transform);
    botLeft.x += rectCenter.x;
    botLeft.y += rectCenter.y;
    
    CGPoint botRight = CGPointMake(CGRectGetMaxX(originRect), CGRectGetMaxY(originRect));
    botRight = CGPointApplyAffineTransform(botRight, transform);
    botRight.x += rectCenter.x;
    botRight.y += rectCenter.y;
    
    self.isUpsideDown = !((round(topLeft.y + topRight.y) < round(botLeft.y + botRight.y)) || ACC_FLOAT_EQUAL_TO(angle, M_PI_2));
    return !self.isUpsideDown ? @[@(topLeft.x),@(topLeft.y),@(topRight.x),@(topRight.y),@(botLeft.x),@(botLeft.y),@(botRight.x),@(botRight.y)] : @[@(botRight.x),@(botRight.y),@(botLeft.x),@(botLeft.y),@(topRight.x),@(topRight.y),@(topLeft.x),@(topLeft.y)];
}

// 返回锚定边的中点
- (CGPoint)getShowLocation {
    NSArray<NSNumber *> *pts = self.transformedRectCornerPoints;
    if (self.transformedRectCornerPoints.count != 8) return CGPointZero;
    CGPoint point;
    if (self.arrowDirection != AWEEditStickerBubbleArrowDirectionDown) {
        point = CGPointMake((f(pts[0]) + f(pts[2])) / 2.f, (f(pts[1]) + f(pts[3])) / 2.f);
    } else {
        point = CGPointMake((f(pts[4]) + f(pts[6])) / 2.f, (f(pts[5]) + f(pts[7])) / 2.f);
    }
    return point;
}

// 获取锚定边的水平长度
- (CGFloat)getRotateRectWidth {
    NSArray<NSNumber *> *pts = self.transformedRectCornerPoints;
    if (self.transformedRectCornerPoints.count != 8) return 0.f;
    CGFloat width = 0.f;
    if (self.arrowDirection != AWEEditStickerBubbleArrowDirectionDown) {
        width = f(pts[2]) - f(pts[0]);
    } else {
        width = f(pts[6]) - f(pts[4]);
    }
    return width;
}

- (CGFloat)getRotateXOffsetWith:(CGFloat)yOffset {
    NSArray<NSNumber *> *pts = self.transformedRectCornerPoints;
    if (self.transformedRectCornerPoints.count != 8) return 0.f;
    // y=kx+b
    CGFloat k;
    // corner case
    if (ACC_FLOAT_EQUAL_TO(f(pts[2]), f(pts[0])) || ACC_FLOAT_EQUAL_TO(f(pts[6]), f(pts[4]))) {
        return 0.f;
    }
    if (self.arrowDirection != AWEEditStickerBubbleArrowDirectionDown) {
        k = (f(pts[3])-f(pts[1])) / (f(pts[2])-f(pts[0]));
    } else {
        k = (f(pts[7])-f(pts[5])) / (f(pts[6])-f(pts[4]));
    }
    return !ACC_FLOAT_EQUAL_ZERO(k) ? (yOffset / k) : 0.f;
}

- (CGFloat)getRotateYOffsetWith:(CGFloat)xOffset {
    NSArray<NSNumber *> *pts = self.transformedRectCornerPoints;
    if (self.transformedRectCornerPoints.count != 8) return 0.f;
    // y=kx+b
    CGFloat k;
    // corner case
    if (ACC_FLOAT_EQUAL_TO(f(pts[2]), f(pts[0])) || ACC_FLOAT_EQUAL_TO(f(pts[6]), f(pts[4]))) {
        return 0.f;
    }
    if (self.arrowDirection != AWEEditStickerBubbleArrowDirectionDown) {
        k = (f(pts[3])-f(pts[1])) / (f(pts[2])-f(pts[0]));
    } else {
        k = (f(pts[7])-f(pts[5])) / (f(pts[6])-f(pts[4]));
    }
    CGFloat max = k * ABS(f(pts[2]) - f(pts[0])) / 2;
    CGFloat suggestYOffset = k * xOffset;
    
    CGFloat rs = ({
        CGFloat res;
        if (ABS(max) < ABS(suggestYOffset)) {
            if ((suggestYOffset < 0 && max > 0)
                || (suggestYOffset > 0 && max < 0)) {
                max = -max;
            }
            res = max;
        } else {
            res = suggestYOffset;
        }
        res;
    });

    return rs;
}

@end



static NSMutableDictionary<NSString *, AWEEditStickerBubbleManager *> *managerMap;
static NSString *const AWEEditBubbleSharedManagerName = @"com.shared.AWEEditStickerBubbleManager";

@interface AWEEditStickerBubbleManager()

@property (nonatomic, strong) AWEEditStickerBubbleView *bubble;

@end

@implementation AWEEditStickerBubbleManager
@dynamic bubbleVisible;
@dynamic bubbleItems;
@dynamic arrowDirection;

+ (instancetype)sharedManager {
    static AWEEditStickerBubbleManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initWithName:AWEEditBubbleSharedManagerName];
    });
    return instance;
}

+ (instancetype)managerWithName:(NSString *)name {
    return [[self alloc] initWithName:name];
}

- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        name = name ?: @"";
        _name = name;
        if (!managerMap) {
            managerMap = @{}.mutableCopy;
        }
        managerMap[name] = self;
    }
    return self;
}

- (void)destroy {
    if ([self.name isEqualToString:AWEEditBubbleSharedManagerName]) {
        return;
    }
    [managerMap removeObjectForKey:self.name];
}

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

#pragma mark - Public

- (void)setBubbleVisible:(BOOL)bubbleVisible animated:(BOOL)animated {
    [self.bubble setBubbleVisible:bubbleVisible animated:animated];
    [self p_notifyBubbleVisibleDidChanged];
}

- (void)setRect:(CGRect)rect touchPoint:(CGPoint)touchPoint transform:(CGAffineTransform)transform inParentView:(UIView *)parentView {
    UIView *defaultView = ACCBLOCK_INVOKE(self.defaultTargetView);
    [self.bubble setRect:rect touchPoint:touchPoint transform:transform inParentView:parentView?:defaultView];
}

- (void)update {
    [self.bubble update];
}

#pragma mark - setter && getter

- (BOOL)isBubbleVisible {
    return self.bubble.bubbleVisible;
}

- (void)setBubbleVisible:(BOOL)bubbleVisible {
    self.bubble.bubbleVisible = bubbleVisible;
    [self p_notifyBubbleVisibleDidChanged];
}

- (NSArray<AWEEditStickerBubbleItem *> *)bubbleItems {
    return self.bubble.bubbleItems;
}

- (void)setBubbleItems:(NSArray<AWEEditStickerBubbleItem *> *)bubbleItems {
    self.bubble.bubbleItems = bubbleItems;
}

- (AWEEditStickerBubbleArrowDirection)arrowDirection {
    return self.bubble.arrowDirection;
}

- (void)setArrowDirection:(AWEEditStickerBubbleArrowDirection)arrowDirection {
    self.bubble.arrowDirection = arrowDirection;
}

- (AWEEditStickerBubbleView *)bubble {
    if (!_bubble) {
        _bubble = [[AWEEditStickerBubbleView alloc] init];
        _bubble.alpha = 0;
    }
    return _bubble;
}

- (void)p_notifyBubbleVisibleDidChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ACCEditStickerBubbleVisableDidChangedNotify object:nil userInfo:@{
        
        ACCEditStickerBubbleVisableDidChangedNotifyGetNameKey : self.name?:@"",
        ACCEditStickerBubbleVisableDidChangedNotifyGetVisableKey : @(self.bubbleVisible)
    }];
}

#pragma mark - Hash

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        return [self.name isEqualToString:[(typeof(self))other name]];
    }
}

- (NSUInteger)hash
{
    return self.name.hash;
}

@end

@implementation AWEEditStickerBubbleManager (AWEEditSticker)

+ (instancetype)videoStickerBubbleManager {
    NSString *name = @"com.video.AWEEditStickerBubbleManager";
    return managerMap[name] ?: [self managerWithName:name];
}

+ (instancetype)interactiveStickerBubbleManager {
    NSString *name = @"com.interactive.AWEEditStickerBubbleManager";
    return managerMap[name] ?: [self managerWithName:name];
}

+ (instancetype)textStickerBubbleManager {
    NSString *name = @"com.text.AWEEditStickerBubbleManager";
    return managerMap[name] ?: [self managerWithName:name];
}

@end

@implementation AWEEditStickerBubbleItem

- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title actionBlock:(dispatch_block_t)actionBlock {
    if (self = [super init]) {
        _image = image;
        _title = title;
        _actionBlock = actionBlock;
    }
    return self;
}

@end

@implementation AWEEditStickerBubbleViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.textLabel.font = [ACCFont() acc_boldSystemFontOfSize:14];
    self.textLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    self.textLabel.numberOfLines = 1;
    
    self.sepLine = ({
        UIView *line = [UIView new];
        line.backgroundColor = ACCResourceColor(ACCUIColorConstLineInverse);
        line;
    });
    [self.contentView addSubview:self.sepLine];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [UIView animateWithDuration:.1 animations:^{
        self.imageView.alpha = .5;
        self.textLabel.alpha = .5;
    }];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [UIView animateWithDuration:.1 animations:^{
        self.imageView.alpha = 1;
        self.textLabel.alpha = 1;
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentH = self.acc_height - ACCBubbleCellSepLineHeight;
    self.imageView.acc_size = CGSizeMake(ACCBubbleCellImageWidth, ACCBubbleCellImageWidth);
    self.imageView.acc_left = ACCBubbleCellMargin;
    self.imageView.acc_centerY = contentH/2;
    
    [self.textLabel sizeToFit];
    self.textLabel.acc_left = self.imageView.acc_right + ACCBubbleCellImageTextPadding;
    self.textLabel.acc_centerY = self.imageView.acc_centerY;
    
    self.sepLine.frame = CGRectMake(0, contentH, self.acc_width, ACCBubbleCellSepLineHeight);
}

- (void)showBubbleShakeAnimation
{
    CAAnimation * (^generateShakeAniBlock)(CGFloat) = ^(CGFloat delayTime) {
        CAKeyframeAnimation *animation = [CAKeyframeAnimation new];
        animation.keyPath = @"transform.rotation";
        animation.keyTimes = @[@(0.0),@(0.18),@(0.36),@(0.56),@(0.8),@(1.0)];
        animation.values = @[@(0.0),@(M_PI*0.16),@(-M_PI*0.16),@(M_PI*0.1),@(-M_PI*0.06),@(0.0)];
        animation.duration = 1.0;
        animation.beginTime = CACurrentMediaTime() + delayTime;
        return animation;
    };
    
    CAAnimation *firstAni = ACCBLOCK_INVOKE(generateShakeAniBlock, 0.f);
    [self.imageView.layer addAnimation:firstAni forKey:@"bubbleShakeAnimation_1"];
    CAAnimation *secondAni = ACCBLOCK_INVOKE(generateShakeAniBlock, 1.75);
    [self.imageView.layer addAnimation:secondAni forKey:@"bubbleShakeAnimation_2"];
    
    self.bubbleItem.showShakeAnimation = NO;
    ACCBLOCK_INVOKE(self.bubbleItem.shakeAniPerformedBlock);
}

+ (NSString *)awe_identifier {
    return NSStringFromClass(self);
}

#pragma mark - setter

- (void)setBubbleItem:(AWEEditStickerBubbleItem *)bubbleItem {
    _bubbleItem = bubbleItem;
    self.imageView.image = bubbleItem.image;
    self.textLabel.text = bubbleItem.title;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
