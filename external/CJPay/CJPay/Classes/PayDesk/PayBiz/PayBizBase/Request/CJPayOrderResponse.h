//
//  CJPayOrderResponse.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/24.
//

#import "CJPayIntergratedBaseResponse.h"

@interface CJPayOrderResponse : CJPayIntergratedBaseResponse

@property (nonatomic, copy)NSString *channelData;
@property (nonatomic, copy) NSString *tradeType;
@property (nonatomic, copy)NSString *ptCode;

- (NSDictionary *)payDataDict;

@end
