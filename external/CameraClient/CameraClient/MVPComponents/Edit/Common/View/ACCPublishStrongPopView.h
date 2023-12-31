//
//  ACCPublishStrongPopView.h
//  CameraClient-Pods-Aweme
//
//  Created by ZZZ on 2021/2/23.
//

#import <UIKit/UIKit.h>

@interface ACCPublishStrongPopView : UIView

+ (void)showInView:(UIView *)view publishBlock:(void (^)(void))publishBlock;

@end
