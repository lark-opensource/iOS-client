//
//  BDWPluginUserContentController.h
//  BDMonitorProtocol
//
//  Created by 李琢鹏 on 2020/1/15.
//

#import <Foundation/Foundation.h>
#import <BDWebCore/IWKPluginHandleResultObj.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDWPluginUserContentController <NSObject>

@optional
/*! @abstract Adds a user script.
 @param userScript The user script to add.
*/
- (IWKPluginHandleResultType)addUserScript:(WKUserScript *)userScript;

/*! @abstract Removes all associated user scripts.
*/
- (IWKPluginHandleResultType)removeAllUserScripts;

/*! @abstract Adds a script message handler.
 @param scriptMessageHandler The message handler to add.
 @param name The name of the message handler.
 @discussion Adding a scriptMessageHandler adds a function
 window.webkit.messageHandlers.<name>.postMessage(<messageBody>) for all
 frames.
 */
- (IWKPluginHandleResultType)addScriptMessageHandler:(id <WKScriptMessageHandler>)scriptMessageHandler name:(NSString *)name;

/*! @abstract Removes a script message handler.
 @param name The name of the message handler to remove.
 */
- (IWKPluginHandleResultType)removeScriptMessageHandlerForName:(NSString *)name;

/*! @abstract Adds a content rule list.
 @param contentRuleList The content rule list to add.
 */
- (IWKPluginHandleResultType)addContentRuleList:(WKContentRuleList *)contentRuleList API_AVAILABLE(macos(10.13), ios(11.0));

/*! @abstract Removes a content rule list.
 @param contentRuleList The content rule list to remove.
 */
- (IWKPluginHandleResultType)removeContentRuleList:(WKContentRuleList *)contentRuleList API_AVAILABLE(macos(10.13), ios(11.0));

/*! @abstract Removes all associated content rule lists.
 */
- (IWKPluginHandleResultType)removeAllContentRuleLists API_AVAILABLE(macos(10.13), ios(11.0));

@end

NS_ASSUME_NONNULL_END
