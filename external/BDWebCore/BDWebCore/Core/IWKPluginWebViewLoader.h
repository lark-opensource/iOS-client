//
//  IWKPluginWebViewLoader.h
//  BDWebCore
//
//  Created by li keliang on 2019/6/30.
//

#import <WebKit/WebKit.h>
#import <BDWebCore/IWKPluginHandleResultObj.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IWKPluginWebViewLoader <NSObject>

@optional
- (IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadRequest:(NSURLRequest *)request;

/*! @abstract Navigates to the requested file URL on the filesystem.
 @param URL The file URL to which to navigate.
 @param readAccessURL The URL to allow read access to.
 @discussion If readAccessURL references a single file, only that file may be loaded by WebKit.
 If readAccessURL references a directory, files inside that file may be loaded by WebKit.
 @result A new navigation for the given file URL.
 */
- (IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL API_AVAILABLE(macosx(10.11), ios(9.0));

/*! @abstract Sets the webpage contents and base URL.
 @param string The string to use as the contents of the webpage.
 @param baseURL A URL that is used to resolve relative URLs within the document.
 @result A new navigation.
 */
- (IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL;

/*! @abstract Sets the webpage contents and base URL.
 @param data The data to use as the contents of the webpage.
 @param MIMEType The MIME type of the data.
 @param characterEncodingName The data's character encoding name.
 @param baseURL A URL that is used to resolve relative URLs within the document.
 @result A new navigation.
 */
- (IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL API_AVAILABLE(macosx(10.11), ios(9.0));

@end

NS_ASSUME_NONNULL_END
