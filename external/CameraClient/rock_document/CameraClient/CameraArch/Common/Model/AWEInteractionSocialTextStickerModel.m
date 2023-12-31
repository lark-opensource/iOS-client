//
//  AWEInteractionSocialTextStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/21.
//

#import "AWEInteractionSocialTextStickerModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCURLTransModelProtocol.h>
#import <IESInject/IESInjectDefines.h>
#import "AWEInteractionStickerModel+DAddition.h"
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "AWEInteractionMentionStickerModel.h"
#import "AWEInteractionHashtagStickerModel.h"

@implementation AWEInteractionStickerSocialMentionModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{ @"userID"      : @"user_id",
              @"avatarThumb" : @"avatar_thumb",
              @"secUserID"   : @"sec_uid",
              @"userName"    : @"user_name",
              @"signature"   : @"signature",
              @"followStatus" : @"follow_status",
    };
}

+ (NSValueTransformer *)avatarThumbJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[IESAutoInline(ACCBaseServiceProvider(), ACCURLTransModelProtocol) URLModelImplClass]];
}

@end

@implementation AWEInteractionStickerSocialHashtagModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{ @"hashtagName" : @"hashtag_name",
              @"hashtagID"   : @"hashtag_id"};
}

@end

@implementation  AWEInteractionStickerAssociatedSocialModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{ @"type"         : @"type",
              @"hashtagModel" : @"hashtag_info",
              @"mentionModel" : @"mention_info"
    };
}

+ (NSValueTransformer *)mentionModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:AWEInteractionStickerSocialMentionModel.class];
}

+ (NSValueTransformer *)hashtagModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:AWEInteractionStickerSocialHashtagModel.class];
}

- (BOOL)isValid
{
    if (self.type == AWEInteractionStickerAssociatedSociaTypeMention) {
        
        return (!ACC_isEmptyString(self.mentionModel.userID) &&
                !ACC_isEmptyString(self.mentionModel.secUserID) &&
                !ACC_isEmptyString(self.mentionModel.userName));
        
    } else if (self.type == AWEInteractionStickerAssociatedSociaTypeHashtag) {
        
        return (!ACC_isEmptyString(self.hashtagModel.hashtagID)&&
                !ACC_isEmptyString(self.hashtagModel.hashtagName));
    }
    
    return NO;
}

+ (instancetype)modelWithMention:(AWEInteractionStickerSocialMentionModel *)mention
{
    AWEInteractionStickerAssociatedSocialModel *model = [[AWEInteractionStickerAssociatedSocialModel alloc] init];
    model.type = AWEInteractionStickerAssociatedSociaTypeMention;
    model.mentionModel = mention;
    return model;
}

+ (instancetype)modelWithHashTag:(AWEInteractionStickerSocialHashtagModel *)hashtag
{
    AWEInteractionStickerAssociatedSocialModel *model = [[AWEInteractionStickerAssociatedSocialModel alloc] init];
    model.type = AWEInteractionStickerAssociatedSociaTypeHashtag;
    model.hashtagModel = hashtag;
    return model;
}

@end

@implementation AWEInteractionSocialTextStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *keyPathDict = [NSMutableDictionary dictionaryWithDictionary:[[[AWEInteractionSocialTextStickerModel class] superclass] JSONKeyPathsByPropertyKey]];
    [keyPathDict addEntriesFromDictionary:@{
        @"textSocialInfos" : @"text_interaction"
    }];
    return keyPathDict;
}

+ (NSValueTransformer *)textSocialInfosJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:AWEInteractionStickerAssociatedSocialModel.class];
}

- (NSInteger)indexFromType
{
    return 0;
}

@end


@implementation AWEInteractionStickerModel(SocialHelper)

- (NSArray<AWEInteractionStickerAssociatedSocialModel *> *)validTextSocialInfos
{
    NSMutableArray <AWEInteractionStickerAssociatedSocialModel *> *ret = [NSMutableArray array];
    if (![self isKindOfClass:[AWEInteractionSocialTextStickerModel class]]) {
        return @[];
    }
    [((AWEInteractionSocialTextStickerModel *)self).textSocialInfos enumerateObjectsUsingBlock:^(AWEInteractionStickerAssociatedSocialModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isValid]) {
            [ret addObject:obj];
        }
    }];
    return [ret copy];
}

- (AWEInteractionStickerSocialMentionModel *)convertMentionStickerMentionModel
{
    if (![self isKindOfClass:[AWEInteractionMentionStickerModel class]] || !((AWEInteractionMentionStickerModel *)self).mentionedUserInfo) {
        return nil;
    }
    NSError *error = nil;
    AWEInteractionStickerSocialMentionModel *mentionModel = [MTLJSONAdapter modelOfClass:[AWEInteractionStickerSocialMentionModel class] fromJSONDictionary:((AWEInteractionMentionStickerModel *)self).mentionedUserInfo error:&error];
    
    return mentionModel;
}

- (AWEInteractionStickerSocialHashtagModel *)convertHashtagStickerHashtagModel
{
    if (![self isKindOfClass:[AWEInteractionHashtagStickerModel class]] || !((AWEInteractionHashtagStickerModel *)self).hashtagInfo) {
        return nil;
    }
    NSError *error = nil;
    AWEInteractionStickerSocialHashtagModel *hashtagModel = [MTLJSONAdapter modelOfClass:[AWEInteractionStickerSocialHashtagModel class] fromJSONDictionary:((AWEInteractionHashtagStickerModel *)self).hashtagInfo error:&error];
    
    return hashtagModel;
}

- (NSInteger)p_validSocialCountForType:(AWEInteractionStickerAssociatedSociaType)socialType
{
    __block NSInteger ret = 0;
    
    if (self.type == AWEInteractionStickerTypeHashtag) {
        AWEInteractionHashtagStickerModel *hashtagSticker = ([self isKindOfClass:[AWEInteractionHashtagStickerModel class]]) ? (AWEInteractionHashtagStickerModel *)self : nil;
        if (socialType == AWEInteractionStickerAssociatedSociaTypeHashtag) {
            if (!ACC_isEmptyString([hashtagSticker.hashtagInfo acc_stringValueForKey:@"hashtag_id"]) &&
                !ACC_isEmptyString([hashtagSticker.hashtagInfo acc_stringValueForKey:@"hashtag_name"])) {
                ret ++;
            }
        }
        
    } else if (self.type == AWEInteractionStickerTypeMention) {
        AWEInteractionMentionStickerModel *mentionSticker = ([self isKindOfClass:[AWEInteractionMentionStickerModel class]]) ? (AWEInteractionMentionStickerModel *)self : nil;
        if (socialType == AWEInteractionStickerAssociatedSociaTypeMention) {
            if (!ACC_isEmptyString([mentionSticker.mentionedUserInfo acc_stringValueForKey:@"user_id"]) &&
                !ACC_isEmptyString([mentionSticker.mentionedUserInfo acc_stringValueForKey:@"sec_uid"]) &&
                !ACC_isEmptyString([mentionSticker.mentionedUserInfo acc_stringValueForKey:@"user_name"])) {
                ret++;
            }
        }
        
    } else if (self.type == AWEInteractionStickerTypeSocialText) {
        
        if ([self isKindOfClass:[AWEInteractionSocialTextStickerModel class]]) {
            [[((AWEInteractionSocialTextStickerModel *)self).textSocialInfos copy] enumerateObjectsUsingBlock:^(AWEInteractionStickerAssociatedSocialModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if (obj.type == socialType && obj.isValid) {
                    ret++;
                }
            }];
        }
    }
    
    return ret;
}

- (NSInteger)validHashtagCount
{
    return [self p_validSocialCountForType:AWEInteractionStickerAssociatedSociaTypeHashtag];
}

- (NSInteger)validMentionCount
{
    return [self p_validSocialCountForType:AWEInteractionStickerAssociatedSociaTypeMention];
}

@end
