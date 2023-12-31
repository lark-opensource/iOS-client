//
//  CJPayThemeModeService.h
//  Pods
//
//  Created by 易培淮 on 2020/9/25.
//

#ifndef CJPayThemeModeService_h
#define CJPayThemeModeService_h


NS_ASSUME_NONNULL_BEGIN

#define CJPayThemeModeChangeNotification @"CJPayThemeModeChangeNotification"

@protocol CJPayThemeModeService <NSObject>

// 设置主题模式
- (void)i_setThemeModeWithParam:(nonnull NSString *)param;
- (NSString *)i_themeModeStr;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayThemeModeService_h */
