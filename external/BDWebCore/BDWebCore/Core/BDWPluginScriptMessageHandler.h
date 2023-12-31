//
//  BDWPluginScriptMessageHandler.h
//  BDWebCore
//
//  Created by 李琢鹏 on 2020/1/16.
//

#import <BDWebCore/IWKPluginHandleResultObj.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDWPluginScriptMessageHandler <NSObject>

@optional
- (IWKPluginHandleResultType)bdw_userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;

@end

NS_ASSUME_NONNULL_END
