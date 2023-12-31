//
//  CJPayBindCardFirstStepOCRView.h
//  Pods
//
//  Created by xiuyuanLee on 2020/12/10.
//

#import <UIKit/UIKit.h>
#import "CJPayBindCardFirstStepBaseInputView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBindCardFirstStepOCRView : UIView

#pragma mark - block
@property (nonatomic, copy) void(^didOCRButtonClickBlock)(void);

@end

NS_ASSUME_NONNULL_END
