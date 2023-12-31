//
//  ACCEditorMusicComponent.m
//  Indexer
//
//  Created by tangxiaoxi on 2021/10/13.
//

#import "ACCEditorMusicComponent.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCEditMusicBizModule.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>

@interface ACCEditorMusicComponent ()

@property (nonatomic, strong) ACCEditMusicBizModule *musicBizModule;

@end

@implementation ACCEditorMusicComponent

- (void)setupWithCompletion:(void (^)(NSError *))completion
{
    self.musicBizModule = [[ACCEditMusicBizModule alloc] initWithServiceProvider:self.serviceProvider];
    
    [self.musicBizModule setup];

    @weakify(self);
    [self.musicBizModule downloadMusicIfneedWithCompletion:^(id<ACCMusicModelProtocol>  _Nullable model, NSError *error) {
        @strongify(self);
        if (model) {
            [self.musicBizModule replaceAudio:model.loaclAssetUrl completeBlock:^{
                ACCBLOCK_INVOKE(completion,nil);
            }];
        } else {
            ACCBLOCK_INVOKE(completion,error);
        }
    }];
}

@end
