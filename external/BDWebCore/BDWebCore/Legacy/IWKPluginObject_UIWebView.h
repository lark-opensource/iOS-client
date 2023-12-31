//
//  IWKPluginObject_UIWebView.h
//  BDWebCore
//
//  Created by li keliang on 14/11/2019.
//

#import <BDWebCore/IWKPluginObject.h>
#import <BDWebCore/IWKPluginWebViewBuilder_UIWebView.h>
#import <BDWebCore/IWKPluginWebViewLoader_UIWebView.h>
#import <BDWebCore/IWKPluginNavigationDelegate_UIWebView.h>

NS_ASSUME_NONNULL_BEGIN

@interface IWKPluginObject_UIWebView : NSObject<IWKPluginObject, IWKPluginWebViewBuilder_UIWebView, IWKPluginWebViewLoader_UIWebView, IWKPluginNavigationDelegate_UIWebView>

@property (nonatomic,  readonly, assign) IWKPluginObjectPriority priority;

@property (nonatomic, readwrite, assign) BOOL enable;

@property (nonatomic, readwrite, strong) NSString *uniqueID;

@end

NS_ASSUME_NONNULL_END
