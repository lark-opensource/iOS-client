//
//  ACCEditorMusicConfigAssembler.h
//  Indexer
//
//  Created by tangxiaoxi on 2021/10/12.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ACCMusicConfigStrategy) {
    ACCMusicConfigStrategyNone = 0,
    ACCMusicConfigStrategyHot = 1,
    ACCMusicConfigStrategySpecify = 2,
};

@protocol ACCMusicModelProtocol;

@interface ACCMusicConfig : NSObject

@property (nonatomic, assign) ACCMusicConfigStrategy strategy;
@property (nonatomic, strong, nullable) NSString *musicId;
@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> music;

@end


@interface ACCEditorMusicConfigAssembler : NSObject

@property (nonatomic, strong, readonly, nullable) ACCMusicConfig *config;

- (void)autoConfigMusicWithHotList;
- (void)specifyMusicWithMusicId:(NSString * _Nonnull)musicId;
- (void)specifyMusicWithMusic:(id<ACCMusicModelProtocol> _Nonnull)music;

- (void)prepareOnCompletion:(void (^)(NSError * _Nonnull))completionHandler;

@end
