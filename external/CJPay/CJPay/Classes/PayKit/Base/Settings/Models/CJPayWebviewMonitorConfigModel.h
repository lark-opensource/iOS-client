//
//  CJPayWebviewMonitorConfigModel.h
//  Pods
//
//  Created by 尚怀军 on 2021/7/27.
//

#import <JSONModel/JSONModel.h>
NS_ASSUME_NONNULL_BEGIN

@interface CJPayWebviewMonitorConfigModel : JSONModel

@property (nonatomic, assign) BOOL enableMonitor;
@property (nonatomic, assign) NSInteger detectBlankDelayTime;
@property (nonatomic, assign) NSInteger webviewPageTimeoutTime;

@end

NS_ASSUME_NONNULL_END
