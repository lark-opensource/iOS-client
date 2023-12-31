//
//  BDXLynxScrollView.h
//  BDXElement
//
//  Created by li keliang on 2020/3/9.
//

#import <Lynx/LynxUIScroller.h>

NS_ASSUME_NONNULL_BEGIN
@class BDXLynxScrollView;

@protocol BDXLynxScrollViewBounceView <NSObject>

@optional
- (void)bdx_updateOverflowText:(nullable NSString *)text;

@end

@protocol BDXLynxScrollViewUIDelegate <NSObject>

@optional
+ (UIView<BDXLynxScrollViewBounceView> *)BDXLynxScrollViewBounceView:(BDXLynxScrollView *)scrollView;

@end

@interface BDXLynxScrollView : LynxUIScroller

@property (class) Class<BDXLynxScrollViewUIDelegate> BDXUIDelegate;

@end

NS_ASSUME_NONNULL_END
