//
//  IESLiveResouceBundle+String.h
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceBundle.h"
#import "IESLiveResouceHTMLParser.h"

@interface IESLiveResouceBundle (String)

- (NSString * (^)(NSString *key))string;

/**
 参数格式: <%= param %>
 存储方式: "price_text" = "价格:<%= price %>元"
 调用: MY.movie.fstring(@"price_text", @{@"price":@"34.5"});
 */
- (NSString * (^)(NSString *key, NSDictionary *params))fstring;

/**
 富文本支持样式: <span>,<strike>
 存储方式: "cinema_price" = "<span style="color:#00ff00;background-color:#0000ff;font-size:40px;">影院价</span><strike>80</strike>元"
 调用: MY.movie.astring(@"cinema_price");
 */
- (NSAttributedString * (^)(NSString *key))astring;
- (NSAttributedString * (^)(NSString *key, NSDictionary *params))afstring;

@end
