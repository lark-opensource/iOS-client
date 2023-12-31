//
//  BDXLynxSwiperCellLayout.h
//  BDXElement
//
//  Created by bill on 2020/3/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXLynxSwiperTransformLayoutType) {
    BDXLynxSwiperTransformLayoutNormal,
    BDXLynxSwiperTransformLayoutLinear,
    BDXLynxSwiperTransformLayoutCoverflow,
    BDXLynxSwiperTransformLayoutFlatCoverflow,
    BDXLynxSwiperTransformLayoutMultiplePages,
    BDXLynxSwiperTransformLayoutCarry,
};

@class BDXLynxSwiperTransformLayout;
@protocol BDXLynxSwiperTransformLayoutDelegate <NSObject>

// initialize layout attributes
- (void)pagerViewTransformLayout:(BDXLynxSwiperTransformLayout *)pagerViewTransformLayout initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes;

// apply layout attributes
- (void)pagerViewTransformLayout:(BDXLynxSwiperTransformLayout *)pagerViewTransformLayout applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes;

@end


@interface BDXLynxSwiperViewLayout : NSObject

@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGFloat previousMargin;
@property (nonatomic, assign) CGFloat nextMargin;
@property (nonatomic, assign) CGFloat startMargin;
@property (nonatomic, assign) CGFloat endMargin;

@property (nonatomic, assign) UIEdgeInsets sectionInset;

@property (nonatomic, assign) BDXLynxSwiperTransformLayoutType layoutType;

@property (nonatomic, assign) CGFloat minimumScale; // sacle default 0.8
@property (nonatomic, assign) CGFloat minimumAlpha; // alpha default 1.0
@property (nonatomic, assign) CGFloat maximumAngle; // angle is % default 0.2

@property (nonatomic, assign) CGFloat maxXScale; // default 1.0,only effect on carry layout
@property (nonatomic, assign) CGFloat minXScale; // default 0.8,only effect on carry layout
@property (nonatomic, assign) CGFloat maxYScale; // default 1.0,only effect on carry layout
@property (nonatomic, assign) CGFloat minYScale; // default 0.8,only effect on carry layout
@property (nonatomic, assign) CGFloat normTranslationFactor; // default 0.0,only effect on carry layout

@property (nonatomic, assign) BOOL isInfiniteLoop;  // infinte scroll
@property (nonatomic, assign) CGFloat rateOfChange; // scale and angle change rate
@property (nonatomic, assign) BOOL adjustSpacingWhenScroling;

@property (nonatomic, assign) BOOL vertical;
/**
 pageView cell item vertical centering
 */
@property (nonatomic, assign) BOOL itemVerticalCenter;

/**
 first and last item horizontalc enter, when isInfiniteLoop is NO
 */
@property (nonatomic, assign) BOOL itemHorizontalCenter;

// sectionInset
@property (nonatomic, assign, readonly) UIEdgeInsets onlyOneSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets firstSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets lastSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets middleSectionInset;
@property (nonatomic, assign) BOOL isRTL;

@end

@interface BDXLynxSwiperTransformLayout : UICollectionViewFlowLayout

@property (nonatomic, strong) BDXLynxSwiperViewLayout *layout;

@property (nonatomic, weak, nullable) id<BDXLynxSwiperTransformLayoutDelegate> delegate;

@end

// use to fix the flipHoriztonal problem
@interface BDXLynxSwiperTransformLayoutNonFlip : BDXLynxSwiperTransformLayout

@end

NS_ASSUME_NONNULL_END
