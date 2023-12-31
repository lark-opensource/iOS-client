//
//  TMAThumnailView.h
//  OPPluginBiz
//
//  Created by houjihu on 2018/8/29.
//

#import <UIKit/UIKit.h>

extern const CGFloat TMAThumnailViewSize;

@interface TMAThumnailView : UIView

/// 点击删除按钮后的执行动作
@property (nonatomic, copy) void (^deleteImageCompletionBlock)(void);

/// 显示本地/网络图片
- (void)showImageWithPath:(NSString *)imagePath;

/// 显示图片
- (void)showImage:(UIImage *)image;

@end
