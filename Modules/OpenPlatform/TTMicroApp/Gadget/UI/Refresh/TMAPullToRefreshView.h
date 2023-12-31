//
//  TMAPullToRefreshView.h
//  Timor
//
//  Created by muhuai on 2018/1/18.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMARefreshView.h"

@interface TMAPullToRefreshView : UIView <TMARefreshAnimationDelegate>

@property (nonatomic, copy) NSString *backgroundTextStyle;

@end
