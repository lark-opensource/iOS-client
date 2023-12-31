//
//  CJPayQuickBindCardQuickFrontHeaderViewModel.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/13.
//

#import "CJPayBaseListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayQuickBindCardFooterViewModel : CJPayBaseListViewModel
@end

@interface CJPayQuickBindCardHeaderViewModel : CJPayBaseListViewModel

@property (nonatomic, assign) BOOL isAdaptTheme; //是否需要适配主题, 默认为NO
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;

@end

@interface CJPayQuickBindCardQuickFrontHeaderViewModel : CJPayBaseListViewModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;

@end

NS_ASSUME_NONNULL_END
