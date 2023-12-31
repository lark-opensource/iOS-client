//
//  CJPayUniteSignModule.h
//  CJPay-021e20ba
//
//  Created by 王新华 on 2022/9/15.
//

#ifndef CJPayUniteSignModule_h
#define CJPayUniteSignModule_h

@protocol CJPayUniteSignModule
//独立签约
- (void)i_uniteSignOnlyWithDataDict:(NSDictionary *)dataDict delegate:(id<CJPayAPIDelegate>)delegate;

@end

#endif /* CJPayUniteSignModule_h */
