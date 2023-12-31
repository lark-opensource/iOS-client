//
//  BDXPageCategoryViewModel.h
//  BDXElement
//
//  Created by hanzheng on 2021/3/5.
//

#import <UIKit/UIKit.h>
#import "BDXCategoryViewDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXPageViewProps : NSObject

@property (nonatomic, strong) UIColor* tabbarBackground;
@property (nonatomic, assign) NSUInteger selectedTextSize;
@property (nonatomic, assign) CGFloat tabPaddingLeft;
@property (nonatomic, assign) CGFloat tabPaddingRight;
@property (nonatomic, assign) CGFloat tabHeight;
@property (nonatomic, strong) NSString* textBoldMode;
@property (nonatomic, assign) BDXTabLayoutGravity layoutGravity;
@property (nonatomic, assign) NSInteger selectIndex;



@property (nonatomic, strong) UIColor* selectTextColor;
@property (nonatomic, assign) NSUInteger unSelectedTextSize;
@property (nonatomic, strong) UIColor* unSelectTextColor;

@property (nonatomic, strong) UIColor* tabIndicatorColor;
@property (nonatomic, assign) BOOL hideIndicator;
@property (nonatomic, assign) NSUInteger tabInterSpace;
@property (nonatomic, assign) NSUInteger tabIndicatorWidth;
@property (nonatomic, assign) NSUInteger tabIndicatorHeight;
@property (nonatomic, assign) CGFloat tabIndicatorRadius;

@property (nonatomic, assign) CGFloat borderTop;
@property (nonatomic, assign) CGFloat borderHeight;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong) UIColor* borderColor;
@property (nonatomic, assign) BOOL hideBorder;

@property (nonatomic, assign) BOOL allowHorizontalBounce;
@property (nonatomic, assign) BOOL reserveEdgeback;
@property (nonatomic, assign) BOOL allowHorizontalGesture;
@property (nonatomic, assign) int gestureDirection;
@property (nonatomic, assign) CGFloat gestureBeginOffset;

@end

NS_ASSUME_NONNULL_END
