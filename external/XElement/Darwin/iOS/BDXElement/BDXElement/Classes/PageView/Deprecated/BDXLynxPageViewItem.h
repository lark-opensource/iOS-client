//
//  BDXLynxPageViewItem.h
//  BDXElement
//
//  Created by AKing on 2020/9/21.
//

#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

@class BDXPageItemView;

@protocol BDXPageItemViewSizeDelegate <NSObject>

- (void)pageItemViewDidChangeFrame:(UIView *)view;

- (void)pageItemViewDidChangeContentSize:(UIScrollView *)scrollView;

@end

@protocol BDXPageItemViewTagDelegate <NSObject>

- (void)tagDidChanged:(BDXPageItemView *)view;

@end


@interface BDXPageItemView : UIView

@end

@interface BDXLynxPageViewItem : LynxUI <BDXPageItemView *>

@property (nonatomic, copy, readonly) NSString *tag;

@property (nonatomic, weak) id <BDXPageItemViewSizeDelegate> sizeDelegate;

@property (nonatomic, weak) id <BDXPageItemViewTagDelegate> tagDelegate;

- (nullable UIScrollView *)childScrollView;

@end

NS_ASSUME_NONNULL_END
