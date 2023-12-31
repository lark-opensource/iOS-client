//
//  BDNativeWebComponentLogic.h
//  ByteWebView
//
//  Created by liuyunxuan on 2019/6/12.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "BDNativeWebContainerObject.h"
#import "BDNativeWebBaseComponent.h"
NS_ASSUME_NONNULL_BEGIN

@protocol BDNativeWebComponentLogicDelegate <NSObject>

@required
- (void)bdNative_attachWebScrollViewByIndex:(NSInteger)index tryCount:(NSInteger)trycount scrollContentWidth:(NSInteger)scrollContentWidth completion:(nonnull void (^)(UIScrollView *scrollView, NSError * _Nullable error))completion;

- (WKWebView *)bdNative_nativeComponentWebView;

@end

@interface BDNativeWebComponentLogic : NSObject

@property (nonatomic, weak) id <BDNativeWebComponentLogicDelegate>delegate;

@property (nonatomic, strong) NSMutableDictionary <NSString *, BDNativeWebContainerObject *>*containerObjects;

- (void)handleInvokeFunction:(NSDictionary *)params completion:(void (^)(BOOL succeed, NSDictionary * _Nullable param))completion;
- (void)handleCallbackFunction:(NSDictionary *)params completion:(void (^)(BOOL succeed, NSDictionary * _Nullable param))completion;

- (void)dispatchAction:(NSDictionary *)param callback:(BDNativeDispatchActionCallback)callback;

- (NSArray *)checkNativeInfos;

- (void)clearNativeComponentWithIFrameID:(NSString *)iFrameID;

- (void)clearNativeComponent;

+ (void)registerGloablNativeComponent:(NSArray<Class> *)components;

- (void)registerNativeComponent:(NSArray<Class> *)components;

@end

NS_ASSUME_NONNULL_END
