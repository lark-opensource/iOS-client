//
//  ACCTextStickerExtraModel.m
//  CameraClient-Pods-Aweme-CameraResource
//
//  Created by imqiuhang on 2021/3/23.
//

#import "ACCTextStickerExtraModel.h"
#import <CreativeKit/ACCMacros.h>
#import <Mantle/EXTKeyPathCoding.h>

@implementation ACCTextStickerExtraModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    ACCTextStickerExtraModel *model;
    return
    @{
        @keypath(model, type)        : @"type",
        @keypath(model, start)       : @"start",
        @keypath(model, end)         : @"end",
        @keypath(model, userId)      : @"user_id",
        @keypath(model, secUserID)   : @"sec_uid",
        @keypath(model, nickname)    : @"nickname",
        @keypath(model, hashtagName) : @"hashtag_name",
        @keypath(model, followStatus): @"follow_status",
    };
}

- (NSInteger)length
{
    return self.end - self.start;
}

- (void)setLength:(NSInteger)length
{
    self.end = self.start + length;
}

+ (instancetype)hashtagExtraWithHashtagName:(NSString *)hashtagName
{
    ACCTextStickerExtraModel *model = [ACCTextStickerExtraModel new];
    model.type = ACCTextStickerExtraTypeHashtag;
    model.hashtagName = hashtagName;
    return model;
}

+ (instancetype)mentionExtraWithUserId:(NSString *)userId
                             secUserID:(NSString *)secUserID
                              nickName:(NSString *)nickName
                          followStatus:(NSInteger)followStatus
{
    ACCTextStickerExtraModel *model = [ACCTextStickerExtraModel new];
    model.type = ACCTextStickerExtraTypeMention;
    model.userId = userId;
    model.secUserID = secUserID;
    model.nickname = nickName;
    model.followStatus = followStatus;
    return model;
}

- (BOOL)isValid
{
    switch (self.type) {
        case ACCTextStickerExtraTypeHashtag: {
            return !ACC_isEmptyString(self.hashtagName);
        }

        case ACCTextStickerExtraTypeMention: {
            return (!ACC_isEmptyString(self.userId) &&
                    !ACC_isEmptyString(self.secUserID) &&
                    !ACC_isEmptyString(self.nickname));
        }
    }
    
    return NO;
}

+ (NSInteger)numberOfValidExtrasInList:(NSArray <ACCTextStickerExtraModel *> *)extras
                               forType:(ACCTextStickerExtraType)extraType;
{
    return [self filteredValidExtrasInList:extras forType:extraType].count;
}

+ (NSArray<ACCTextStickerExtraModel *> *)filteredValidExtrasInList:(NSArray<ACCTextStickerExtraModel *> *)extras
                                                           forType:(ACCTextStickerExtraType)extraType
{
    NSMutableArray <ACCTextStickerExtraModel *> *ret = [NSMutableArray array];
    
    [[extras copy] enumerateObjectsUsingBlock:^(ACCTextStickerExtraModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.type == extraType && obj.isValid) {
            [ret addObject:obj];
        }
    }];
    
    return [ret copy];
}

+ (NSArray<ACCTextStickerExtraModel *> *)sortedByLocationAscendingWithExtras:(NSArray<ACCTextStickerExtraModel *> *)extras
{
    // In the order from front to back, not the order of addition
    return [[extras copy] sortedArrayUsingComparator:^NSComparisonResult(ACCTextStickerExtraModel *_Nonnull obj1, ACCTextStickerExtraModel *_Nonnull obj2) {
        
        if (obj1.start > obj2.start) {
            return NSOrderedDescending;
        } else if (obj1.start < obj2.start) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    }];
}

@end
