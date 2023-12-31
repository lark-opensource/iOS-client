//
//  CJPayFullResultCardView.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/3/9.
//

#import "CJPayBaseLynxView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayFullResultCardView : CJPayBaseLynxView

@property (nonatomic, copy) NSString *isLynxViewButtonClickStr;

- (void)resetLynxCardSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
