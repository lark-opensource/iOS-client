//
//  BDWPluginWebViewEvaluator.h
//  BDWebCore
//
//  Created by 李琢鹏 on 2020/1/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDWPluginWebViewEvaluator <NSObject>

/* @abstract Evaluates the given JavaScript string.
 @param javaScriptString The JavaScript string to evaluate.
 @param completionHandler A block to invoke when script evaluation completes or fails.
 @discussion The completionHandler is passed the result of the script evaluation or an error.
*/
- (IWKPluginHandleResultType)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler;


@end

NS_ASSUME_NONNULL_END
