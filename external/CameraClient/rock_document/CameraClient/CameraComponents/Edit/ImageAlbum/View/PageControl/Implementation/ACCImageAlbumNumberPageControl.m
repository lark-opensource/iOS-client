//
//  ACCImageAlbumNumberPageControl.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/10/15.
//

#import "ACCImageAlbumNumberPageControl.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

#pragma mark - BorderLabel

@interface BorderLabel : UILabel

@end

@implementation BorderLabel

- (void)drawTextInRect:(CGRect)rect
{
    CGSize shadowOffset = self.shadowOffset;
    UIColor *textColor = self.textColor;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(c, .5f);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    
    CGContextSetTextDrawingMode(c, kCGTextStroke);
    self.textColor = [UIColor colorWithWhite:0.f alpha:.12f];
    [super drawTextInRect:rect];
    
    CGContextSetTextDrawingMode(c, kCGTextFill);
    self.textColor = textColor;
    self.shadowOffset = CGSizeMake(0, 0);
    [super drawTextInRect:rect];
    
    self.shadowOffset = shadowOffset;
}

@end

#pragma mark - ACCImageAlbumNumberPageControl

@interface ACCImageAlbumNumberPageControl ()

@property (nonatomic, strong, nullable) BorderLabel *combinedNumLbl;

@end

@implementation ACCImageAlbumNumberPageControl

@synthesize totalPageNum;
@synthesize currentPageIndex;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.combinedNumLbl.frame = CGRectMake(0, 0, 60.f, self.frame.size.height);
    self.combinedNumLbl.center = CGPointMake(self.frame.size.width / 2.f, self.frame.size.height / 2.f);
}

#pragma mark - Public Methods

- (void)updateCurrentPageIndex:(NSInteger)currentPageIndex
{
    self.currentPageIndex = currentPageIndex;
    self.combinedNumLbl.text = [NSString stringWithFormat:@"%@/%@", @(currentPageIndex + 1), @(self.totalPageNum)];
}

- (void)resetTotalPageNum:(NSInteger)totalPageNum currentPageIndex:(NSInteger)currentPageIndex
{
    self.totalPageNum = totalPageNum;
    [self updateCurrentPageIndex:currentPageIndex];
}

#pragma mark - Private Methods

- (void)p_setupUI
{
    [self addSubview:self.combinedNumLbl];
}

#pragma mark - Getters

- (BorderLabel *)combinedNumLbl
{
    if (!_combinedNumLbl) {
        _combinedNumLbl = [[BorderLabel alloc] init];
        _combinedNumLbl.textColor = ACCResourceColor(ACCColorConstTextInverse3);
        _combinedNumLbl.textAlignment = NSTextAlignmentCenter;
        _combinedNumLbl.font = [ACCFont() acc_systemFontOfSize:14.f weight:ACCFontWeightMedium];
        _combinedNumLbl.text = @"1/1";
    }
    return _combinedNumLbl;
}

@end
