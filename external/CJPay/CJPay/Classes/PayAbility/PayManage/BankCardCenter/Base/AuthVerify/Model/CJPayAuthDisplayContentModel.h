//
//  CJPayAuthDisplayContentModel.h
//  CJPay
//
//  Created by wangxiaohong on 2020/5/25.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayAuthDisplayContentModel : JSONModel

@property (nonatomic, copy) NSString *displayDesc;
@property (nonatomic, copy) NSString *displayUrl;

@end

NS_ASSUME_NONNULL_END
