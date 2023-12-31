//
//  ACCLynxView.h
//  AWEStudioService-Pods-Aweme
//
//  Created by wanghongyu on 2021/9/9.
//

#import <Foundation/Foundation.h>

@protocol ACCLynxViewConfigProtocol <NSObject>
- (NSString *)accessKey;
- (NSDictionary<NSString*, Class>*)lynxComponet;
@end


@protocol ACCLynxContainerViewProtocol <NSObject>
- (void)sendEvent:(nonnull NSString *)event params:(nonnull NSDictionary *)params;
@end


@protocol ACCLynxContainerViewDelegate <NSObject>
@optional
- (void)containerViewDidChangeIntrinsicContentSize:(CGSize)size;
- (void)containerViewWillStartLoading;
- (void)containerViewDidStartLoading;

- (void)containerViewDidFetchResourceWithURL:(nullable NSString *)urlString;
- (void)containerViewDidFetchedResourceWithURL:(nullable NSString *)urlString error:(nullable NSError *)error;

- (void)containerViewDidFirstScreen;

- (void)containerViewDidFinishLoadWithURL:(nullable NSString *)url;
- (void)containerViewDidLoadFailedWithURL:(nullable NSString *)url error:(nullable NSError *)error;

- (void)containerViewDidUpdate;
- (void)containerViewDidReceiveError:(nullable NSError *)error;
- (void)containerViewDidReceivePerformance:(nullable NSDictionary *)perfDict;
@end



@protocol BDXLynxViewProtocol;
@class BDXBridgeMethod;

@interface ACCLynxView : UIView<ACCLynxContainerViewProtocol>
@property (nonatomic, weak, nullable) id<ACCLynxContainerViewDelegate> lifeCycleDelegate;
@property (nonatomic, strong, readonly, nullable) UIView<BDXLynxViewProtocol> *lynxView;

- (void)loadURL:(nonnull NSURL *)url
      withProps:(nullable NSDictionary * )props
       xbridges:(nullable NSArray<BDXBridgeMethod *> *)xbridges
         config:(nonnull id<ACCLynxViewConfigProtocol>)config;

- (void)updateProps:(nullable NSDictionary *)props;

- (void)reloadProps:(nullable NSDictionary *)props;

- (void)sendEvent:(nullable NSString *)event params:(nullable NSDictionary *)params;
@end

