//
//  BDXLynxSwiperSlideControl.h
//  BDXElement
//
//  Created by bill on 2020/3/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxSwiperSlideControl : UIControl

@property (nonatomic, assign) NSInteger numberOfPages;          // default is 0
@property (nonatomic, assign) NSInteger currentPage;            // default is 0. value pinned to 0..numberOfPages-1

@property (nonatomic, assign) BOOL hidesForSinglePage;          // hide the the indicator if there is only one page. default is NO

@property (nonatomic, assign) CGFloat pageIndicatorSpaing;
@property (nonatomic, assign) UIEdgeInsets contentInset; // center will ignore this
@property (nonatomic, assign ,readonly) CGSize contentSize; // real content size

// override super
//@property (nonatomic, assign) UIControlContentVerticalAlignment contentVerticalAlignment;     // how to position content vertically inside control. default is center
//@property (nonatomic, assign) UIControlContentHorizontalAlignment contentHorizontalAlignment; // how to position content hozontally inside control. default is center

// indicatorTint color
@property (nullable, nonatomic,strong) UIColor *pageIndicatorTintColor;
@property (nullable, nonatomic,strong) UIColor *currentPageIndicatorTintColor;

// indicator image
@property (nullable, nonatomic,strong) UIImage *pageIndicatorImage;
@property (nullable, nonatomic,strong) UIImage *currentPageIndicatorImage;

@property (nonatomic, assign) UIViewContentMode indicatorImageContentMode; // default is UIViewContentModeCenter

@property (nonatomic, assign) CGSize pageIndicatorSize; // indicator size
@property (nonatomic, assign) CGSize currentPageIndicatorSize; // default pageIndicatorSize

@property (nonatomic, assign) CGFloat animateDuring; // default 0.3

@property (nonatomic, assign) BOOL isRTL;

- (void)setCurrentPage:(NSInteger)currentPage animate:(BOOL)animate;

@end

NS_ASSUME_NONNULL_END
