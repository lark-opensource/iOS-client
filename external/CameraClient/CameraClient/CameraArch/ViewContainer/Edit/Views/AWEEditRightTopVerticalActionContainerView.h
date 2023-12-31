//
//  AWEEditRightTopVerticalActionContainerView.h
//  Pods
//
//  Created by 赖霄冰 on 2019/7/5.
//

#import <UIKit/UIKit.h>
#import "AWEEditRightTopActionContainerViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEEditRightTopVerticalActionContainerView : UIView<AWEEditRightTopActionContainerViewProtocol>

+ (NSInteger)containerViewMaxItemCount:(NSInteger)foldExihibitCount maxUnfoldedItemCount:(NSInteger)maxUnfoldedItemCount ignoreUnfoldLimitCount:(NSInteger)ignoreUnfoldLimitCount ignoreWhitelist:(BOOL)ignoreWhitelist;
+ (NSInteger)containerViewMaxUnfoldedItemCount:(BOOL)isFromIM;

@end

NS_ASSUME_NONNULL_END
