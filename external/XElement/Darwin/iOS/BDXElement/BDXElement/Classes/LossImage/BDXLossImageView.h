//
//  BDXLossImageView.h
//  Pods
//
//  Created by hanzheng on 2021/2/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXLossImageViewDelegate

-(void)viewWillMoveToWindow:(UIWindow *)window;

@end

@interface BDXLossImageView : UIImageView

@property(nonatomic,weak)id<BDXLossImageViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
