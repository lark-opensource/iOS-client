//
//  BDImageOptionView.h
//  BDWebImage_Example
//
//  Created by 陈奕 on 2020/4/7.
//  Copyright © 2020 Bytedance.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDImageOptionView : UIView

- (void)updateItems;
- (void)setSaveAction:(void (^)(void))block;

@end

NS_ASSUME_NONNULL_END
