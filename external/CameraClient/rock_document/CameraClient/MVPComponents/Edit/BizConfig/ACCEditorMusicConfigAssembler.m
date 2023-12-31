//
//  ACCEditorMusicConfigAssembler.m
//  Indexer
//
//  Created by tangxiaoxi on 2021/10/12.
//

#import "ACCEditorMusicConfigAssembler.h"
#import "ACCEditMusicBizModule.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreativeKit/ACCMacros.h>

@implementation ACCMusicConfig

@end

@interface ACCEditorMusicConfigAssembler ()

@property (nonatomic, strong, readwrite, nullable) ACCMusicConfig *config;

@end

@implementation ACCEditorMusicConfigAssembler

- (void)autoConfigMusicWithHotList
{
    ACCMusicConfig *config = [[ACCMusicConfig alloc] init];
    config.strategy = ACCMusicConfigStrategyHot;
    self.config = config;
}

- (void)specifyMusicWithMusicId:(NSString * _Nonnull)musicId
{
    ACCMusicConfig *config = [[ACCMusicConfig alloc] init];
    config.strategy = ACCMusicConfigStrategySpecify;
    config.musicId = musicId;
    self.config = config;
}

- (void)specifyMusicWithMusic:(id<ACCMusicModelProtocol> _Nonnull)music
{
    ACCMusicConfig *config = [[ACCMusicConfig alloc] init];
    config.strategy = ACCMusicConfigStrategySpecify;
    config.music = music;
    self.config = config;
}

- (void)prepareOnCompletion:(void (^)(NSError * _Nullable))completionHandler
{
    //请求音乐模型后期可以优化到进入编辑页后。当前为避免音乐模型相关联的逻辑出问题(如音乐绑定挑战)，先请求到模型，保证进入编辑前带有完整的音乐模型。
    ACCMusicConfig *config = self.config;
    [ACCEditMusicBizModule fetchMusicModelWithMusicConfig:self.config completion:^(id<ACCMusicModelProtocol>  _Nullable model, NSError *error) {
        config.music = model;
        ACCBLOCK_INVOKE(completionHandler,error);
    }];
}

@end
