//
//  BDXLynxVideoPlayerPro.h
//
// Copyright 2022 The Lynx Authors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDXLynxVideoProInterface.h"


NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxVideoProModel : NSObject

@property (nonatomic, strong) NSString *propsSrc;
@property (nonatomic, strong) NSString *propsPoster;
@property (nonatomic, assign) BOOL propsAutoplay;
@property (nonatomic, assign) BOOL propsLoop;
@property (nonatomic, assign) NSTimeInterval propsInitTime;
@property (nonatomic, assign) NSInteger propsRate;
@property (nonatomic, assign) BOOL propsAutoLifeCycle;
@property (nonatomic, strong) NSString *propsTag;
@property (nonatomic, assign) NSInteger propsCacheSize;
@property (nonatomic, assign) BOOL initMuted;
@property (nonatomic, strong) NSString *objectfit;
@property (nonatomic, strong) NSString *preloadKey;
@property (nonatomic, strong) NSDictionary *header;

@property (nonatomic, strong) NSString *playAuthDomain;
@property (nonatomic, strong) NSString *playAuthToken;
@property (nonatomic, strong) NSString *itemID;
@property (nonatomic, strong) NSString *playUrlString;
@property (nonatomic, strong) NSDictionary *videoModel;

@end


@interface BDXLynxVideoPlayerPro : UIView <BDXLynxVideoProPlayerProtocol>
@property (nonatomic, assign) BOOL createEngineEveryTime;
@property (nonatomic, strong) BDXLynxVideoProModel *playingModel;
@property (nonatomic, weak) id<BDXLynxVideoProUIProtocol> uiDelegate;
@property (nonatomic, assign) BOOL renderByMetal;
@property (nonatomic, assign) BOOL asyncClose;

@end

NS_ASSUME_NONNULL_END
