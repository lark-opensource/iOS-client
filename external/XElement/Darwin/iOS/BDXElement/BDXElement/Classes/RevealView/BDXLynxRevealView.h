//
//  BDXLynxRevealView.h
//  BDXElement
//
//  Created by bytedance on 2020/10/26.
//

#import <UIKit/UIKit.h>
#import <Lynx/LynxUI.h>
#import "BDXLynxRevealViewInnerView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXRevealView : UIView

@end

@interface BDXLynxRevealView : LynxUI <BDXRevealView *>

@end

NS_ASSUME_NONNULL_END
