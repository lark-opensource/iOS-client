//
//  BDPShareContext.h
//  Timor
//
//  Created by MacPu on 2019/2/26.
//

#import <Foundation/Foundation.h>
#import "BDPCommon.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPShareContext : NSObject

@property (nonatomic, weak) UIViewController *controller;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, copy) NSString *query;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *shareChannel; //点击分享面板后选择的分享方式
@property (nonatomic, copy) NSString *imgURI; //分享图片审核后的URI
@property (nonatomic, weak) BDPCommon *appCommon;
@property (nonatomic, strong) NSDictionary *extra;
@property (nonatomic, assign) BOOL withShareTicket;
@property (nonatomic, copy) NSString *linkTitle;
@property (nonatomic, copy) NSString *templateId;
@property (nonatomic, copy) NSString *desc;

@end

NS_ASSUME_NONNULL_END
