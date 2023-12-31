//
//  ACCTextStickerExtraModel.h
//  CameraClient-Pods-Aweme-CameraResource
//
//  Created by imqiuhang on 2021/3/23.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCTextStickerExtraType) {
    ACCTextStickerExtraTypeHashtag = 0,
    ACCTextStickerExtraTypeMention = 1,
};

@interface ACCTextStickerExtraModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) ACCTextStickerExtraType type;

// Left closed, right open, [), length = end - start
@property (nonatomic, assign) NSInteger start;
@property (nonatomic, assign) NSInteger end;
- (NSInteger)length;
- (void)setLength:(NSInteger)length;

// mention info
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *secUserID;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, assign) NSInteger followStatus;

// hashtag info
@property (nonatomic, copy) NSString *hashtagName;

+ (instancetype)hashtagExtraWithHashtagName:(NSString *)hashtagName;

+ (instancetype)mentionExtraWithUserId:(NSString *)userId
                             secUserID:(NSString *)secUserID
                              nickName:(NSString *)nickName
                          followStatus:(NSInteger)followStatus;

- (BOOL)isValid;

+ (NSInteger)numberOfValidExtrasInList:(NSArray <ACCTextStickerExtraModel *> *_Nullable)extras
                               forType:(ACCTextStickerExtraType)extraType;

+ (NSArray <ACCTextStickerExtraModel *> *_Nullable)filteredValidExtrasInList:(NSArray <ACCTextStickerExtraModel *> *_Nullable)extras
                                                                     forType:(ACCTextStickerExtraType)extraType;

+ (NSArray <ACCTextStickerExtraModel *> *_Nullable)sortedByLocationAscendingWithExtras:(NSArray <ACCTextStickerExtraModel *> *_Nullable)extras;

@end

NS_ASSUME_NONNULL_END
