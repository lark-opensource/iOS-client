//
//  BDLynxViewClient.h
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#import <Foundation/Foundation.h>
#import "LynxImageFetcher.h"
#import "LynxViewClient.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDLynxClientLifeCycleDelegate <NSObject>

@optional
- (void)viewDidChangeIntrinsicContentSize:(CGSize)size;
- (void)viewDidStartLoading;
- (void)viewDidFirstScreen;
- (void)viewDidPageUpdate;
- (void)viewDidFinishLoadWithURL:(NSString *)url;
- (void)viewDidUpdate;
- (void)viewDidRecieveError:(NSError *)error;
- (void)viewDidLoadFailedWithUrl:(NSString *)url error:(NSError *)error;
- (void)viewDidReceiveFirstLoad:(CFTimeInterval)loadTime;
- (void)viewDidConstructJSRuntime;

@end

@interface BDLynxViewClient : NSObject <LynxViewLifecycle, LynxImageFetcher>

@property(nonatomic, weak) id<BDLynxClientLifeCycleDelegate> lifeCycleDelegate;

- (instancetype)initWithChannel:(NSString *)channel
                     bundlePath:(NSString *)path
                      sessionID:(NSString *)sessionID
                  pageStartTime:(CFTimeInterval)time;
- (void)updateChannel:(NSString *)channel
           bundlePath:(NSString *)path
            sessionID:(NSString *)sessionID
        pageStartTime:(CFTimeInterval)time;
- (void)updateBid:(NSString *)bid pid:(NSString *)pid;

// Hybrid Monitor
- (CFTimeInterval)currentTimeSince1970;
- (void)trackLynxRenderPipelineTrigger:(NSString *)trigger;
- (void)trackLynxLifeCycleTrigger:(NSString *)trigger
                          logType:(NSString *)logType
                          service:(NSString *)service;

- (nonnull dispatch_block_t)loadImageWithURL:(nonnull NSURL *)url
                                        size:(CGSize)targetSize
                                 contextInfo:(nullable NSDictionary *)contextInfo
                                  completion:(nonnull LynxImageLoadCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
