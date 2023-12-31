//
//  CJPayOCRScanWindowView.h
//  CJPay
//
//  Created by 尚怀军 on 2020/5/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define CJ_OCR_SCAN_WIDTH 327.0
#define CJ_OCR_SCAN_HEIGHT 212.0

@interface CJPayOCRScanWindowView : UIView

- (void)showScanLineView:(BOOL)shouldShow;

@end

NS_ASSUME_NONNULL_END
