//
//  EMAAudioPlayer.h
//  TimorImpl
//
//  Created by MacPu on 2019/5/27.
//

#import <Foundation/Foundation.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import "BDPAudioModel.h"
#import <OPFoundation/BDPTimorClient.h>

NS_ASSUME_NONNULL_BEGIN

///Audio Player Protocol(For Audio Selector)
@protocol BDPAudioPlayer<NSObject>

@property (nonatomic, assign) NSInteger audioID;

@property (nonatomic, assign, readonly) CGFloat currentTime;
@property (nonatomic, assign, readonly) CGFloat duration;
@property (nonatomic, assign, readonly) CGFloat buffered;
@property (nonatomic, assign, readonly) BOOL paused;
@property (nonatomic, assign, readonly) BOOL ended;
@property (nonatomic, assign, readonly) BOOL playing;

- (NSDictionary * _Nullable)getAudioState;
- (void)setAudioState:(BDPAudioModel *)model;

- (void)playWithCompletion:(void (^ _Nullable)(BOOL, NSString * _Nullable))completion;
- (BOOL)pause;
- (BOOL)stop;
- (void)seek:(CGFloat)time completion:(void (^)(BOOL))completion;
// fireEvent的实现
- (void)fireEvent:(void(^)(NSString * _Nullable event, NSInteger sourceID, NSDictionary * _Nullable data))block;
- (void)onError:(void(^)(id<BDPAudioPlayer> player, NSError * _Nullable error))errorBlock;

@end

@interface EMAAudioPlayer : NSObject <BDPAudioPlayer>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithUniqueID:(OPAppUniqueID *)uniqueID;

@end

NS_ASSUME_NONNULL_END

