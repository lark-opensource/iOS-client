//
//  EMAImageLoadingView.h
//  Article
//
//  Created by Huaqing Luo on 15/4/15.
//
//

#import <UIKit/UIKit.h>

// The view is initialized by a fixed size (100 X 80) (that is, the "size" of "frame" passed to "initWithFrame" is ignored)
@interface EMAImageLoadingView : UIView

/** loadingProgress */
@property(nonatomic, assign)CGFloat loadingProgress;
/** percentLabel */
@property(nonatomic, strong, readonly) UILabel * percentLabel;

@end
