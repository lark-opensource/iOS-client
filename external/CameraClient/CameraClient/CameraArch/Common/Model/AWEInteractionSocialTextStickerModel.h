//
//  AWEInteractionSocialTextStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/21.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <CreationKitArch/ACCURLModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, AWEInteractionStickerAssociatedSociaType) {
    AWEInteractionStickerAssociatedSociaTypeMention = 1,
    AWEInteractionStickerAssociatedSociaTypeHashtag = 2,
};

@interface AWEInteractionStickerSocialMentionModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *secUserID;
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, assign) NSInteger followStatus;
@property (nonatomic, strong) id<ACCURLModelProtocol>avatarThumb;

@end

@interface AWEInteractionStickerSocialHashtagModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *hashtagName;
@property (nonatomic, copy) NSString *hashtagID;

@end

@interface AWEInteractionStickerAssociatedSocialModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) AWEInteractionStickerAssociatedSociaType type;

@property (nonatomic, strong) AWEInteractionStickerSocialHashtagModel *hashtagModel;
@property (nonatomic, strong) AWEInteractionStickerSocialMentionModel *mentionModel;

+ (instancetype)modelWithMention:(AWEInteractionStickerSocialMentionModel *)mention;
+ (instancetype)modelWithHashTag:(AWEInteractionStickerSocialHashtagModel *)hashtag;

- (BOOL)isValid;

@end

@interface AWEInteractionSocialTextStickerModel : AWEInteractionStickerModel

/// 服务端下发或者本地编辑添加的文字贴纸关联的mention / hashtag 数据原始数据
@property (nonatomic, copy) NSArray<AWEInteractionStickerAssociatedSocialModel *> *textSocialInfos;

@end



@interface AWEInteractionStickerModel(SocialHelper)

/// 文字贴纸关联的mention / hashtag 数据，从@see 'textSocialInfos'中过滤出的数据
/// 从服务端过滤的有效的feed数据， 会过滤无效的hashtag和mention，所以如果是本地编辑数据@see 'textSocialInfos'，因为本地很多数据字段不全 例如hashtagId
- (NSArray<AWEInteractionStickerAssociatedSocialModel *> *)validTextSocialInfos;

/// 获取服务端下发的 对应 mention / hashtag / 文字 贴纸各自的绑定数据数量
- (NSInteger)validMentionCount;
- (NSInteger)validHashtagCount;

/// mention / hashtag贴纸的 mentionedUserInfo / hashtagInfo 转换的model
- (AWEInteractionStickerSocialHashtagModel *_Nullable)convertHashtagStickerHashtagModel;
- (AWEInteractionStickerSocialMentionModel *_Nullable)convertMentionStickerMentionModel;

@end

NS_ASSUME_NONNULL_END
