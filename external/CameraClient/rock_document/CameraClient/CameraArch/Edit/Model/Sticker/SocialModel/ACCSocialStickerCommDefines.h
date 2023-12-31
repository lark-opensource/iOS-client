//
//  ACCSocialStickerCommDefines.h
//  CameraClient
//
//  Created by qiuhang on 2020/8/6.
//

#ifndef ACCSocialStickerCommDefines_h
#define ACCSocialStickerCommDefines_h

#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <CreationKitInfra/ACCCommonDefine.h>

typedef NS_ENUM(NSUInteger, ACCSocialStickerType) {
    ACCSocialStickerTypeMention = 1,
    ACCSocialStickerTypeHashTag = 2,
};

static const NSString *ACCSocialMentionStickTagString = @"mention";
static const NSString *ACCSocialHashTagStickTagString = @"hashtag";
static NSString * const ACCSocialNewMentionStickTagString = @"mention2";
static NSString * const ACCSocialNewHashTagStickTagString = @"hashtag2";

// return nil if not matched
NS_INLINE NSNumber *acc_matchedSocialStickTypeWithEffectTagList(NSArray<NSString *> * _Nullable tagList) {
    
    for (NSString *tag in tagList) {
        
        NSString *lowercaseTagString = tag.lowercaseString;
        if ([lowercaseTagString isEqual:ACCSocialMentionStickTagString]) {
            return @(ACCSocialStickerTypeMention);
        } else if ([lowercaseTagString isEqual:ACCSocialHashTagStickTagString]) {
            return @(ACCSocialStickerTypeHashTag);
        } else if ([lowercaseTagString isEqual:ACCSocialNewMentionStickTagString]) {
            return @(ACCSocialStickerTypeMention);
        } else if ([lowercaseTagString isEqual:ACCSocialNewHashTagStickTagString]) {
            return @(ACCSocialStickerTypeHashTag);
        }
    }
    return nil;
}

NS_INLINE BOOL acc_isSupportiveSocialStickWithEffectTagList(NSArray<NSString *> *tagList) {
    return acc_matchedSocialStickTypeWithEffectTagList(tagList) != nil;
}

NS_INLINE AWEInteractionStickerType acc_convertSocialStickerTypeToInteractionStickerType(ACCSocialStickerType socialStickerType) {
    
    switch (socialStickerType) {
        case ACCSocialStickerTypeMention:
            return AWEInteractionStickerTypeMention;
        case ACCSocialStickerTypeHashTag:
            return AWEInteractionStickerTypeHashtag;
    }
    return AWEInteractionStickerTypeNone;
}

NS_INLINE NSNumber *acc_convertSocialStickerTypeFromInteractionStickerType(AWEInteractionStickerType interactionStickerType) {
    
    if (interactionStickerType == AWEInteractionStickerTypeMention) {
        return @(ACCSocialStickerTypeMention);
    } else if (interactionStickerType == AWEInteractionStickerTypeHashtag) {
        return @(ACCSocialStickerTypeHashTag);
    }
    return nil;
}

#define ACCSocialStickerObjUsingCustomerInitOnly \
- (instancetype)init NS_UNAVAILABLE; \
+ (instancetype)new NS_UNAVAILABLE;

#define ACCSocialStickerViewUsingCustomerInitOnly \
ACCSocialStickerObjUsingCustomerInitOnly \
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE; \
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE; \

#endif /* ACCSocialStickerCommDefines_h */
