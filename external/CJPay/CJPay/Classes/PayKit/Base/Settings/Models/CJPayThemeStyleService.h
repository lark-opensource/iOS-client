//
//  CJPayThemeStyleService.h
//  Pods
//
//  Created by 尚怀军 on 2022/3/5.
//

#ifndef CJPayThemeStyleService_h
#define CJPayThemeStyleService_h
NS_ASSUME_NONNULL_BEGIN

@protocol CJPayThemeStyleService <NSObject>

// 设置主题模式
- (void)i_updateThemeStyleWithThemeDic:(nullable NSDictionary *)themeModelDic;

@end

NS_ASSUME_NONNULL_END


#endif /* CJPayThemeStyleService_h */
