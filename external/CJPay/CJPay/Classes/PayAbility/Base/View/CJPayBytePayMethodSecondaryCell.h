//
//  CJPayBytePayMethodSecondaryCellView.h
//  Pods
//
//  Created by wangxiaohong on 2021/4/13.
//

#import "CJPayMethodSecondaryCellView.h"
#import "CJPayUIMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBytePayMethodSecondaryCell : CJPayMethodSecondaryCellView<CJPayBaseLoadingProtocol>

@property (nonatomic, strong, readwrite) UILabel *rightMsgLabel;

@end

NS_ASSUME_NONNULL_END
