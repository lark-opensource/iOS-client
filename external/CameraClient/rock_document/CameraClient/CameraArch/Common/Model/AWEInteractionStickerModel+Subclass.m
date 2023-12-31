//
//  AWEInteractionStickerModel+Subclass.m
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2021/3/24.
//

#import "AWEInteractionStickerModel+Subclass.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "AWEInteractionPOIStickerModel.h"
#import "AWEInteractionLiveStickerModel.h"
#import "AWEInteractionSocialTextStickerModel.h"
#import "AWEInteractionHashtagStickerModel.h"
#import "AWEInteractionMentionStickerModel.h"
#import "AWEInteractionVideoShareStickerModel.h"
#import "AWEInteractionStickerModel+DAddition.h"
#import "AWEInteractionGrootStickerModel.h"
#import "AWEInteractionVideoReplyStickerModel.h"
#import "AWEInteractionVideoReplyCommentStickerModel.h"
#import "AWEInteractionEditTagStickerModel.h"

@implementation AWEInteractionStickerModel (Subclass)

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary
{
    NSInteger type = [JSONDictionary acc_integerValueForKey:@"type"];
    if (type == AWEInteractionStickerTypePOI) {
        return [AWEInteractionPOIStickerModel class];
    }
    
    if (type == AWEInteractionStickerTypeLive) {
        return [AWEInteractionLiveStickerModel class];
    }
    
    if (type == AWEInteractionStickerTypeSocialText) {
        return [AWEInteractionSocialTextStickerModel class];
    }
    
    if (type == AWEInteractionStickerTypeVideoShare) {
        return [AWEInteractionVideoShareStickerModel class];
    }
    
    if (type == AWEInteractionStickerTypeHashtag) {
        return [AWEInteractionHashtagStickerModel class];
    }
    
    if (type == AWEInteractionStickerTypeMention) {
        return [AWEInteractionMentionStickerModel class];
    }
    
    if (type == AWEInteractionStickerTypeGroot) {
        return [AWEInteractionGrootStickerModel class];
    }
    
    if (type == AWEInteractionStickerTypeVideoReply) {
        return [AWEInteractionVideoReplyStickerModel class];
    }
    
    if (type == AWEInteractionStickerTypeVideoReplyComment) {
        return [AWEInteractionVideoReplyCommentStickerModel class];
    }
    
    if (type == AWEInteractionStickerTypeEditTag) {
        return [AWEInteractionEditTagStickerModel class];
    }
    return self;
}

@end
