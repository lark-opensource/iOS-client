//
//  CJPayECCreateOrderModel.h
//  Pods
//
//  Created by 徐天喜 on 2023/06/05.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayFaceVerifyInfo;
@interface CJPayECCreateOrderModel : JSONModel

@property (nonatomic, assign) int st;
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, copy) NSDictionary *data;

@end

NS_ASSUME_NONNULL_END
