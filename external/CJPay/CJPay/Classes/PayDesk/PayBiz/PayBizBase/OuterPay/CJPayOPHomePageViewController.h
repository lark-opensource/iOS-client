//
//  CJPayOPHomePageViewController.h
//  Pods
//
//  Created by xutianxi on 2022/3/28.
//

#import "CJPayHomePageViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayOPHomePageViewController : CJPayHomePageViewController

@property (nonatomic, assign) double lastTimestamp; // 上一次上报 event 的时间戳
@property (nonatomic, assign) BOOL isColdLaunch; // 是否为冷启动进入支付

@end

NS_ASSUME_NONNULL_END
