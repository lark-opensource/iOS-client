//
//  CJPayLocalCardOCRWithPitaya.h
//  cjpay_ocr_optimize
//
//  Created by ByteDance on 2023/5/8.
//

#ifndef CJPayLocalCardOCRPlugin_h
#define CJPayLocalCardOCRPlugin_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 使用Pitaya对银行卡进行本地OCR
@protocol CJPayLocalCardOCRWithPitaya<NSObject>

- (void)initEngine;

- (void)scanWithImage:(UIImage *)image callback:(void (^)(BOOL success, int code, NSString *errorMsg, NSObject *output, UIImage *outImage))callback;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayLocalCardOCRWithPitaya_h */
