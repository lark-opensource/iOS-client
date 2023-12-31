//
//  CJPayCardSignInfoModel.h
//  Pods
//
//  Created by wangxiaohong on 2020/4/12.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCardSignInfoModel : JSONModel

@property (nonatomic, copy) NSString *sign;
@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, copy) NSString *smchId;

@end

NS_ASSUME_NONNULL_END
