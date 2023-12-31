//
//  CAKCircularProgressView.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/4.
//

#import <UIKit/UIKit.h>

@interface CAKCircularProgressView : UIView

// 进度
@property (nonatomic, assign) CGFloat progress;

// 进度条的颜色
@property (nonatomic, strong, nullable) UIColor *progressTintColor;

// 进度条的背景色
@property (nonatomic, strong, nullable) UIColor *progressBackgroundColor;

// 线宽
@property (nonatomic, assign) CGFloat lineWidth;

// 背景宽
@property (nonatomic, assign) CGFloat backgroundWidth;

// 进度条半径
@property (nonatomic, assign) CGFloat progressRadius;
// 背景半径
@property (nonatomic, assign) CGFloat backgroundRadius;

@end
