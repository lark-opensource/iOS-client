//
//  BDWKScriptMessageHandler.h
//  Applog
//
//  Created by bob on 2019/4/16.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 提供H5页面无埋点能力。使得H5页面的无埋点事件通过Native无埋点渠道上报。
@interface BDWKScriptMessageHandler : NSObject<WKScriptMessageHandler>

@property (nonatomic, copy, readonly) NSString *messageName;
@property (nonatomic, copy, readonly)  void (^handler)(WKScriptMessage *message);

+ (instancetype)handlerWithMessageName:(NSString *)messageName handler:(void (^)(WKScriptMessage *message))handler;

@end

NS_ASSUME_NONNULL_END
