//
//  ACCImageAlbumCombinedPageControl.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/10/15.
//

#import "ACCImageAlbumCombinedPageControl.h"
#import "ACCImageAlbumNumberPageControl.h"
#import "ACCImageAlbumDotPageControl.h"

@interface ACCImageAlbumCombinedPageControl ()

@property (nonatomic, strong, nullable) ACCImageAlbumNumberPageControl *numberControl;
@property (nonatomic, strong, nullable) ACCImageAlbumDotPageControl *dotControl;

@end

@implementation ACCImageAlbumCombinedPageControl

@synthesize totalPageNum;
@synthesize currentPageIndex;

- (instancetype)initWithDotDiameter:(CGFloat)diameter visiableCellCount:(NSInteger)visiableCellCount dotSpacing:(CGFloat)dotSpacing
{
    self = [super init];
    if (self) {
        self.numberControl = [[ACCImageAlbumNumberPageControl alloc] init];
        self.dotControl = [[ACCImageAlbumDotPageControl alloc] initWithDotDiameter:diameter visiableCellCount:visiableCellCount dotSpacing:dotSpacing];
        [self p_setupUI];
    }
    return self;
}

- (instancetype)init
{
    self = [self initWithDotDiameter:4.f visiableCellCount:7 dotSpacing:4.f];
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat frameWidth = self.frame.size.width;
    CGFloat frameHeight = self.frame.size.height;
    
    self.numberControl.center = CGPointMake(frameWidth / 2.f, frameHeight / 2.f - self.numberControl.frame.size.height / 2.f);
    self.dotControl.center = CGPointMake(frameWidth / 2.f, frameHeight / 2.f + self.dotControl.frame.size.height / 2.f);
}

#pragma mark - Private Methods

- (void)p_setupUI
{
    [self addSubview:self.numberControl];
    [self addSubview:self.dotControl];
    
    self.numberControl.frame = CGRectMake(0, 0, 60.f, 20.f);
    self.dotControl.frame = CGRectMake(0, 0, 60.f, 20.f);
    
    self.userInteractionEnabled = NO;
}

#pragma mark - Public Methods

- (void)updateCurrentPageIndex:(NSInteger)currentPageIndex
{
    if (self.currentPageIndex == currentPageIndex) {
        return;
    }
    if (currentPageIndex >= self.totalPageNum) {
        return;
    }
    self.currentPageIndex = currentPageIndex;
    [self.numberControl updateCurrentPageIndex:currentPageIndex];
    [self.dotControl updateCurrentPageIndex:currentPageIndex];
}

- (void)resetTotalPageNum:(NSInteger)totalPageNum currentPageIndex:(NSInteger)currentPageIndex
{
    if (self.totalPageNum == totalPageNum && self.currentPageIndex == currentPageIndex) {
        return;
    }
    if (currentPageIndex >= totalPageNum) {
        return;
    }
    self.currentPageIndex = currentPageIndex;
    self.totalPageNum = totalPageNum;
    [self.numberControl resetTotalPageNum:totalPageNum currentPageIndex:currentPageIndex];
    [self.dotControl resetTotalPageNum:totalPageNum currentPageIndex:currentPageIndex];
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [NSString stringWithFormat:@"第%ld页，共%ld页", (long)(self.currentPageIndex + 1), (long)self.totalPageNum];
}

@end
