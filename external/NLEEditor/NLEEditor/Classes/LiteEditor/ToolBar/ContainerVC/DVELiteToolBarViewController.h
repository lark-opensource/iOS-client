//
//  DVELiteToolBarViewController.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/4.
//

#import <UIKit/UIKit.h>
#import "DVEVCContext.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVELiteToolBarDelegate <NSObject>

- (void)panelWillShowWithPreviewChange:(BOOL)shouldChangePreview;

- (void)panelWillDismissWithPreviewChange:(BOOL)shouldChangePreview;

- (UIView *)parentView;

- (CGFloat)crossComponentLeft;

@end

@interface DVELiteToolBarViewController : UIViewController

- (instancetype)initWithVCContext:(DVEVCContext *)vcContext
                         delegate:(id<DVELiteToolBarDelegate>)delegate;

- (void)adjustToolBarIfNeeded:(CGFloat)componentLeft;

- (void)updateCollectionViewFrame;

@end

NS_ASSUME_NONNULL_END
