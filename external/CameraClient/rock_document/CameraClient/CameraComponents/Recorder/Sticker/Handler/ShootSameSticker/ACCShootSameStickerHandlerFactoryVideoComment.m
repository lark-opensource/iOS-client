//
//  ACCShootSameStickerHandlerFactoryVideoComment.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/18.
//

#import "ACCShootSameStickerHandlerFactoryVideoComment.h"
#import "ACCConfigKeyDefines.h"

#import <CreativeKit/ACCMacros.h>
#import <IESInject/IESInject.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import "ACCVideoCommentStickerHandler.h"
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClientModel/ACCVideoCommentModel.h>
#import <CameraClientModel/ACCTextExtraType.h>
#import <CameraClientModel/ACCTextExtraSubType.h>

@implementation ACCShootSameStickerHandlerFactoryVideoComment

- (ACCStickerHandler<ACCShootSameStickerHandlerProtocol> *)createHandlerWithStickerModel:(AWEVideoPublishViewModel *)publishModel
                                                                   shootSameStickerModel:(ACCShootSameStickerModel *)shootSameStickerModel
                                                                        configDelegation:(id<ACCShootSameStickerConfigDelegation>)configDelegation
{
    ACCVideoCommentModel *videoCommentModel = [ACCVideoCommentModel createModelFromJSON:shootSameStickerModel.stickerModelStr];
    
    NSString *atUserText = [NSString stringWithFormat:@"@%@", videoCommentModel.userName];
    NSString *title = [NSString stringWithFormat:@"回复 %@", atUserText];
    if (![publishModel.repoPublishConfig.publishTitle containsString:title]) {
        if (ACCConfigBool(kConfigBool_comment_reply_new_title)) {
            atUserText = [atUserText stringByAppendingString:@"的评论"];
            title = [title stringByAppendingString:@"的评论"];
        }
        title = [title stringByAppendingString:@" "];
        if (!ACC_isEmptyString(publishModel.repoPublishConfig.publishTitle)) {
            title = [title stringByAppendingString:publishModel.repoPublishConfig.publishTitle];
        }
        publishModel.repoPublishConfig.publishTitle = title;
        NSRange atUserRange = [title rangeOfString:atUserText];
        id<ACCTextExtraProtocol> atUserTextExtra = [IESAutoInline(ACCBaseServiceProvider(), ACCModelFactoryServiceProtocol) createTextExtra:ACCTextExtraTypeUser subType:ACCTextExtraSubTypeCommentChain];
        atUserTextExtra.userId = videoCommentModel.userId;
        atUserTextExtra.start = atUserRange.location;
        atUserTextExtra.length = atUserRange.length;

        publishModel.repoPublishConfig.publishTitle = title;
        publishModel.repoDuet.duetOrCommentChainlength = publishModel.repoPublishConfig.publishTitle.length;
        publishModel.repoPublishConfig.titleExtraInfo = (NSArray <id<ACCTextExtraProtocol>> *)@[atUserTextExtra];
    }
    
    return [[ACCVideoCommentStickerHandler alloc] init];
}

- (void)fillPublishModelWithStickerModel:(AWEVideoPublishViewModel *)publisModel
                   shootSameStickerModel:(ACCShootSameStickerModel *)shootSameStickerModel
{
    
}

@end
