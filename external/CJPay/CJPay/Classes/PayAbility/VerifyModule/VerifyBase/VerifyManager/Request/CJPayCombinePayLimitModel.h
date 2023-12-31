//
//  CJPayCombinePayLimitModel.h
//  Pods
//
//  Created by wangxiaohong on 2021/4/20.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCombinePayLimitModel : JSONModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *highLightDesc;
@property (nonatomic, copy) NSString *buttonDesc;

@end

NS_ASSUME_NONNULL_END
