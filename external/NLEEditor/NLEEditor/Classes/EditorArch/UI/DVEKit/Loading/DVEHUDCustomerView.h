//
//  DVEHUDCustomerView.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class LOTAnimationView;
@interface DVEHUDCustomerView : UIImageView

@property (nonatomic, strong) LOTAnimationView *gifView;
@property (nonatomic, strong) UILabel *progressLable;

@property (nonatomic, copy) NSString *showText;

@end

NS_ASSUME_NONNULL_END
