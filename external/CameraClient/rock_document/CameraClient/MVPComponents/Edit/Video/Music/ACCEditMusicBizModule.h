//
//  ACCEditMusicBizModule.h
//  Indexer
//
//  Created by tangxiaoxi on 2021/10/13.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESServiceContainer.h>

@protocol ACCMusicModelProtocol;

@class ACCMusicConfig;

@interface ACCEditMusicBizModule : NSObject

+ (void)fetchMusicModelWithMusicConfig:(ACCMusicConfig * _Nullable)config completion:(void (^ _Nullable)(id<ACCMusicModelProtocol> _Nullable model, NSError *error))completion;

- (instancetype)initWithServiceProvider:(nonnull id<IESServiceProvider>)serviceProvider;

- (void)setup;

- (void)downloadMusicIfneedWithCompletion:(void (^ _Nullable)(id<ACCMusicModelProtocol> _Nullable model, NSError *error))completion;

- (void)replaceAudio:(NSURL * _Nullable)url completeBlock:(void (^ _Nullable)(void))completeBlock;

@end
