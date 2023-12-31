//
//  DVELiteToolBarItemProtocol.h
//  Pods
//
//  Created by Lincoln on 2022/1/4.
//

#import <Foundation/Foundation.h>
#import "DVELitePanelCommonConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class DVELiteToolBarViewModel;

@protocol DVELiteToolBarItemProtocol <NSObject>

- (void)bindViewModel:(DVELiteToolBarViewModel *)viewModel parentView:(UIView *)parentView;

@end

NS_ASSUME_NONNULL_END
