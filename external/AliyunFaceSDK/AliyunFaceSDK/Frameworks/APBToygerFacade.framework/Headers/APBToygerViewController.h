//
//  APFViewController.h
//  APFaceDetectBiz
//
//  Created by 晗羽 on 8/25/16.
//  Copyright © 2016 Alipay. All rights reserved.
//

#import <UIKit/UIKit.h>
NSString *const kAbnormalClose = @"abnormalclose";

@interface APBToygerViewController : UIViewController
@property(nonatomic, strong)ZolozLogMonitor *monitor;                        //埋点
@property(nonatomic, assign) BOOL isClose;

-(void)setStatusBarBackgroundColor:(UIColor *)color;
@end
