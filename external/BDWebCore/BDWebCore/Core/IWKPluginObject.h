//
//  IWKPluginObject.h
//  BDWebCore
//
//  Created by li keliang on 2019/6/27.
//

#import <WebKit/WebKit.h>
#import <BDWebCore/IWKPluginHandleResultObj.h>
#import <BDWebCore/IWKPluginWebViewBuilder.h>
#import <BDWebCore/IWKPluginWebViewLoader.h>
#import <BDWebCore/IWKPluginNavigationDelegate.h>
#import <BDWebCore/IWKPluginUIDelegate.h>
#import <BDWebCore/BDWPluginUserContentController.h>
#import <BDWebCore/BDWPluginScriptMessageHandler.h>
#import <BDWebCore/BDWPluginWebViewEvaluator.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IWKPluginObjectPriority) {
    IWKPluginObjectPriorityLow = 10,
    IWKPluginObjectPriorityDefault = 100,
    IWKPluginObjectPriorityHigh = 200,
    IWKPluginObjectPriorityVeryHigh = 1000
};

@protocol IWKPluginObject <NSObject>

@property (nonatomic,  readonly, assign) IWKPluginObjectPriority priority;

@property (nonatomic, readwrite, assign) BOOL enable;

@property (nonatomic, readwrite, strong) NSString *uniqueID; // Default is class name string

@optional
- (IWKPluginHandleResultType)triggerCustomEvent:(NSString *)event context:(NSDictionary * __nullable)context;

@end

@interface IWKPluginObject : NSObject <IWKPluginObject, IWKPluginWebViewBuilder, IWKPluginWebViewLoader, IWKPluginNavigationDelegate, IWKPluginUIDelegate, BDWPluginUserContentController, BDWPluginScriptMessageHandler, BDWPluginWebViewEvaluator>

@property (nonatomic,  readonly, assign) IWKPluginObjectPriority priority;

@property (nonatomic, readwrite, assign) BOOL enable;

@property (nonatomic, readwrite, strong) NSString *uniqueID;

@end

@protocol IWKClassPlugin<NSObject>

@optional
- (void)onLoad;

@end

@protocol IWKInstancePlugin<NSObject>

@optional
- (void)onLoad:(id)container;

@end

NS_ASSUME_NONNULL_END
