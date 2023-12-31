//
//  AWEInteractionVideoShareStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/20.
//

#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEVideoShareInfoModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *videoItemId;
@property (nonatomic, strong) NSString *authorId;
@property (nonatomic, strong) NSString *authorSecId;
@property (nonatomic, strong) NSString *authorName;
@property (nonatomic, strong) NSString *commentUserId;
@property (nonatomic, strong) NSString *commentUserSecId;
@property (nonatomic, strong) NSString *commentContent;
@property (nonatomic, strong) NSString *commentUserNickname;
@property (nonatomic, strong) NSString *commentId;

@end

@interface AWEInteractionVideoShareStickerModel : AWEInteractionStickerModel

@property (nonatomic, strong) AWEVideoShareInfoModel *videoShareInfo;

@end

NS_ASSUME_NONNULL_END
