//
//  CJPayRetainMsgModel.h
//  Pods
//
//  Created by youerwei on 2022/2/7.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayRetainMsgModel : JSONModel

@property (nonatomic, copy) NSString *leftMsg;
@property (nonatomic, assign) NSInteger leftMsgType; // 营销信息类型，1为金额，2为文案
@property (nonatomic, copy) NSString *rightMsg;
@property (nonatomic, copy) NSString *topLeftMsg;
@property (nonatomic, assign) NSInteger voucherType; // 营销类型，1代表当笔营销，2代表下笔营销，埋点用
@property (nonatomic, copy) NSString *topLeftPosition; // 角标位置 left:金额左边 top_right:右上角

@end

NS_ASSUME_NONNULL_END
