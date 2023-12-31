//
//  CJPayBizWebViewController+WebviewMonitor.h
//  Pods
//
//  Created by 尚怀军 on 2021/8/13.
//

#import "CJPayBizWebViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBizWebViewController (WebviewMonitor)

@property (nonatomic, assign) BOOL hasDetectBlank;
@property (nonatomic, strong) NSMutableDictionary *pageStatusDic;

@end

NS_ASSUME_NONNULL_END
