//
//  AWEVideoEditStickerHeaderView.m
//  CameraClient
//
//  Created by HuangHongsen on 2020/2/5.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVideoEditStickerHeaderView.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEVideoEditStickerHeaderView ()
@property (nonatomic, copy) NSArray *headerViews;
@end

@implementation AWEVideoEditStickerHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];        
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)updateWithTitles:(NSArray *)titles
{
    for (UIView *oldHeaderView in self.headerViews) {
        [oldHeaderView removeFromSuperview];
    }
    NSMutableArray *headerViews = [NSMutableArray array];
    for (NSString *title in titles) {
        UIView *containerView = [[UIView alloc] init];
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() acc_systemFontOfSize:13 weight:ACCFontWeightMedium];
        label.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        label.text = title;
        ACC_LANGUAGE_DISABLE_LOCALIZATION(label);
        
        [containerView addSubview:label];
        
        ACCMasMaker(label, {
            make.left.equalTo(containerView).with.offset(16);
            make.top.equalTo(containerView).with.offset(18);
        });
        [headerViews addObject:containerView];
        
        [self addSubview:containerView];
    }
    self.headerViews = headerViews;
}

- (void)updateWithAttributes:(NSArray *)attributes yOffset:(CGFloat)yOffset
{
    if ([attributes count] != [self.headerViews count]) {
        return ;
    }
    for (NSInteger index = 0; index < [attributes count]; index++) {
        UICollectionViewLayoutAttributes *attribute = attributes[index];
        UIView *headerView = self.headerViews[index];
        headerView.frame = CGRectOffset(attribute.frame, 0, -yOffset);
    }
}

+ (CGFloat)headerHeight
{
    return 40.f;
}

@end
