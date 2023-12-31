//
// Created by 张海阳 on 2020/1/7.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>


@interface CJPayDiscountBanner : JSONModel

@property (nonatomic, copy) NSString *banner;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *stayTime;
@property (nonatomic, copy) NSString *gotoType;     // "0"sdk自带webview，"1"宿主
@property (nonatomic, copy) NSString *resourceNo;
@property (nonatomic, copy) NSString *picUrl;
@property (nonatomic, copy) NSString *jumpUrl;
@property (nonatomic, assign) NSInteger sequence;
@property (nonatomic, assign) NSInteger showTime;

@end
