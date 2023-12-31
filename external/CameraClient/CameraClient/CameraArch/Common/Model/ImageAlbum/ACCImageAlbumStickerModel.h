//
//  ACCImageAlbumStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/31.
//

#import <Foundation/Foundation.h>
#import "ACCImageAlbumEditorDefine.h"
#import "ACCImageAlbumItemBaseResourceModel.h"


NS_ASSUME_NONNULL_BEGIN

@class ACCImageAlbumStickerProps, AWEInteractionStickerModel;

@interface ACCImageAlbumStickerModel : ACCImageAlbumItemDraftResourceRestorableModel

ACCImageEditModeObjUsingCustomerInitOnly;

/// ！！！有别于视频模式，这个不是VE的stickerId，是自行维护的sticker标识，内部会建立一个key-value映射到VE的stickerId
/// 当然上层业务仍然可以当做stickerId去用，因为VE层已经做了隔离，图片编辑的player内会自动维护映射关系
/// 这么做的原因是图片编辑的贴纸是基于恢复模式，stickerId随时会变，所以在player内维护了映射关系，这样业务可以根据id找到准确的贴纸
@property (nonatomic, assign) NSInteger uniqueId;

@property (nonatomic, strong, readonly) ACCImageAlbumStickerProps *_Nonnull param;

/// using [self getAbsoluteFilePath ] to get sticker file path, try  not to use any value from userInfo
@property (nonatomic, copy) NSDictionary *_Nullable userInfo;

@property (nonatomic, copy) NSArray *_Nullable effectInfo;

- (BOOL)isCustomerSticker;

@property (nonatomic, copy) NSString *text;

@end

@interface ACCImageAlbumStickerRecoverModel : NSObject

@property (nonatomic, strong) ACCImageAlbumStickerModel *infoSticker;

@property (nonatomic, strong) AWEInteractionStickerModel *interactionSticker;

@end

@interface ACCImageAlbumStickerProps : MTLModel

@property (nonatomic, assign) CGFloat angle;
// 是相对于图片坐标系的offset
@property (nonatomic, assign) CGFloat offsetX;
@property (nonatomic, assign) CGFloat offsetY;
- (CGPoint)offset;
- (void)updateOffset:(CGPoint)offset;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) CGFloat absoluteScale;
@property (nonatomic, assign) CGFloat alpha;

@property (nonatomic, assign) NSInteger order;

+ (instancetype)defaultProps;
+ (CGPoint)centerOffset;

- (void)updateBoundingBox:(UIEdgeInsets)boundingBox;
- (UIEdgeInsets)boundingBox;

@end

NS_ASSUME_NONNULL_END
