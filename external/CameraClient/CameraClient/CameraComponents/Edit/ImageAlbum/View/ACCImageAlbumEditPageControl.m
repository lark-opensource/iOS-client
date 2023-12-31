//
//  ACCImageAlbumEditPageControl.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/22.
//

#import "ACCImageAlbumEditPageControl.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

@interface ACCImageAlbumEditPageControlNumberView : UIView

- (void)updateTextWithIntValue:(NSInteger)intValue;

@end

@interface ACCImageAlbumEditPageControl ()

@property (nonatomic, strong) ACCImageAlbumEditPageControlNumberView *currentNumberView;
@property (nonatomic, strong) ACCImageAlbumEditPageControlNumberView *totalNumberView;
@property (nonatomic, strong) UILabel *separatorLabel;

@end

@implementation ACCImageAlbumEditPageControl

@synthesize currentPageIndex;
@synthesize totalPageNum;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self p_setup];
    }
    return self;
}

#pragma mark - setter
- (void)setCurrentPage:(NSInteger)currentPage
{
    _currentPage = currentPage;
    [self.currentNumberView updateTextWithIntValue:currentPage + 1];
}

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    _numberOfPages = numberOfPages;
    [self.totalNumberView updateTextWithIntValue:numberOfPages];
}

#pragma mark - view
- (void)p_setup
{
    self.userInteractionEnabled = NO;
    
    self.currentNumberView = ({
        
        ACCImageAlbumEditPageControlNumberView *view = [[ACCImageAlbumEditPageControlNumberView alloc] init];
        [self addSubview:view];
        ACCMasMaker(view, {
            make.centerY.equalTo(self);
            make.left.equalTo(self).inset(12.f);
        });
        view;
    });
    
    self.totalNumberView = ({
        
        ACCImageAlbumEditPageControlNumberView *view = [[ACCImageAlbumEditPageControlNumberView alloc] init];
        [self addSubview:view];
        ACCMasMaker(view, {
            make.centerY.equalTo(self);
            make.right.equalTo(self).inset(12.f);
        });
        view;
    });
    
    self.separatorLabel = ({
        
        UILabel *label = [[UILabel alloc] init];
        [self addSubview:label];
        label.font = [ACCFont() systemFontOfSize:10];
        label.text = @"/";
        label.textColor = [UIColor whiteColor];
        ACCMasMaker(label, {
            make.center.equalTo(self);
        });
        label;
    });
    
    {
        self.backgroundColor = ACCResourceColor(ACCColorBGInverse3);
        self.layer.cornerRadius = self.intrinsicContentSize.height / 2.f;
        self.layer.borderWidth = 0.5f;
        self.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2f].CGColor;
    }
}

#pragma mark - layout
- (CGSize)intrinsicContentSize
{
    return CGSizeMake(64.f, 24.f);
}

#pragma mark - ACCImageAlbumPageControlProtocol Methods

- (void)updateCurrentPageIndex:(NSInteger)currentPageIndex
{
    self.currentPage = currentPageIndex;
}

- (void)resetTotalPageNum:(NSInteger)totalPageNum currentPageIndex:(NSInteger)currentPageIndex
{
    self.currentPage = currentPageIndex;
    self.numberOfPages = totalPageNum;
}

@end


@interface ACCImageAlbumEditPageControlNumberView ()

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation ACCImageAlbumEditPageControlNumberView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self p_setup];
    }
    return self;
}

- (void)p_setup
{
    self.textLabel = ({
        
        UILabel *label = [[UILabel alloc] init];
        [self addSubview:label];
        label.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightMedium];
        label.textColor = [UIColor whiteColor];
        ACCMasMaker(label, {
            make.center.equalTo(self);
        });
        label;
    });
}

- (void)updateTextWithIntValue:(NSInteger)intValue
{
    self.textLabel.text = [@(intValue) stringValue];
}

#pragma mark - layout
- (CGSize)intrinsicContentSize
{
    return CGSizeMake(15.f, 17.f);
}


@end
