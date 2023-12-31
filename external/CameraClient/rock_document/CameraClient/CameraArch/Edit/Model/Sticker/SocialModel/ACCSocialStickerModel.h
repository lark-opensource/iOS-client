//
//  ACCSocialStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by qiuhang on 2020/8/6.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import "ACCSocialStickerCommDefines.h"
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCSocialStickeMentionBindingModel;

@interface ACCSocialStickerModel : NSObject <NSCopying>

- (instancetype)initWithStickerType:(ACCSocialStickerType)stickerType
                   effectIdentifier:(NSString *)effectIdentifier;

#pragma mark - getter
@property (nonatomic, assign, readonly) ACCSocialStickerType stickerType;
@property (nonatomic, copy,   readonly) NSString *effectIdentifier;

- (BOOL)isNotEmpty;
- (BOOL)hasVaildMentionBindingData;
- (BOOL)hasVaildHashtagBindingData;

#pragma mark - setter
@property (nonatomic,   copy) NSString *contentString;
@property (nonatomic, strong) ACCSocialStickeMentionBindingModel *_Nullable mentionBindingModel;
@property (nonatomic,   copy) NSString *extraInfo;
@property (nonatomic, assign) BOOL isAutoAdded;

- (NSDictionary *)trackInfo;

#pragma mark - draft handler
- (void)recoverDataFromDraftJsonString:(NSString *)jsonString;
- (NSString *)draftDataJsonString;

@end

@interface ACCSocialStickeMentionBindingModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *secUserId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, assign) NSInteger followStatus;

+ (instancetype)modelWithSecUserId:(NSString *)secUserId
                            userId:(NSString *)userId
                          userName:(NSString *)userName
                      followStatus:(NSInteger)followStatus;
- (BOOL)isValid;

@end

@interface ACCSocialStickeHashTagBindingModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *hashTagName;

+ (instancetype)modelWithHashTagName:(NSString *)hashTagName;

@end


NS_ASSUME_NONNULL_END
