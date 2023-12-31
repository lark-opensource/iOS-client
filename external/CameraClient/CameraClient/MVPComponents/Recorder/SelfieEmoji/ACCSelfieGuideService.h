//
//  ACCSelfieGuideService.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinghcuan on 2021/9/3.
//

#import <Foundation/Foundation.h>


@protocol ACCSelfieGuideService <NSObject>

- (void)didClickConfirmAction:(UIButton * _Nullable)sender;

- (void)didClickCancleAction:(UIButton * _Nullable)sender;

@end

