//
//  CJPayBindCardTitleInfoModel.h
//  Pods
//
//  Created by renqiang on 2021/7/5.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBindCardTitleInfoModel : JSONModel

@property (nonatomic, copy) NSString *displayIcon;
@property (nonatomic, copy) NSString *displayDesc;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *orderInfo; // 绑卡首页头部订单信息
@property (nonatomic, copy) NSString *iconURL; // 绑卡首页头部订单信息

@end

NS_ASSUME_NONNULL_END
