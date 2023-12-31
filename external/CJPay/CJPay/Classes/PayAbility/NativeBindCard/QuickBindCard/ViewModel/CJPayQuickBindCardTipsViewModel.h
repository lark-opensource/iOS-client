//
//  CJPayQuickBindCardTipsViewModel.h
//  Pods
//
//  Created by xiuyuanLee on 2021/3/4.
//

#import "CJPayBaseListViewModel.h"
#import "CJPayBindCardVCModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayQuickBindCardTipsViewModel : CJPayBaseListViewModel

@property (nonatomic, assign) CJPayBindCardStyle viewStyle;
@property (nonatomic, copy) void(^didClickBlock)(void);

- (NSString *)getContent;

@end

NS_ASSUME_NONNULL_END  
