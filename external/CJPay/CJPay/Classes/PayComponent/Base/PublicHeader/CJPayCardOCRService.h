//
//  CJPayCardOCRService.h
//  Pods
//
//  Created by 尚怀军 on 2021/6/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayCardOCRResultModel;
@protocol CJPayCardOCRService <NSObject>


/**
 * 银行卡卡号OCR
 * param:  识别参数    结构为@{@"app_id": @"", @"merchant_id": @"", @"refer_vc": currentTopVC}
 **/
- (void)i_startCardOCRWithParam:(NSDictionary *)param
                completionBlock:(void(^)(CJPayCardOCRResultModel *resultModel))completionBlock;

@end

NS_ASSUME_NONNULL_END
