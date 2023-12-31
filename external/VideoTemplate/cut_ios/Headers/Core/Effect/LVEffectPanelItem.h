//
//  LVEffectPanelItem.h
//  LVTemplate
//
//  Created by lxp on 2020/2/19.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import "LVModelType.h"

@protocol LVEffectDataSource;

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, LVEffectPanelItemDownloadStatus) {
    LVEffectPanelItemDownloadStatusNone,
    LVEffectPanelItemDownloadStatusLoading,
    LVEffectPanelItemDownloadStatusSuccess,
    LVEffectPanelItemDownloadStatusFailed
};

@protocol LVEffectPanelItemPrototype <NSObject>
@property (nonatomic, assign) LVEffectPanelItemDownloadStatus downloadStatus;
@property (nonatomic, assign, readonly) LVMutablePayloadPlatformSupport platformSupport;
@property (nonatomic, strong, readonly) id<LVEffectDataSource> effect;
@end

@interface LVEffectPanelItem : NSObject

@property (nonatomic, readonly, copy) NSString *urlPrefix;

@property (nonatomic, assign) LVEffectPanelItemDownloadStatus downloadStatus;

@property (nonatomic, assign, readonly) LVMutablePayloadPlatformSupport platformSupport;

@property (nonatomic, readonly) IESEffectModel *effectModel;

- (instancetype)initWithEffectModel:(IESEffectModel *)effectModel;

- (instancetype)initWithEffectModel:(IESEffectModel *)effectModel prefix:(NSString *)prefix;

- (BOOL)isKTV;

@end

@interface LVEffectPanelItem (PanelItemProto)<LVEffectPanelItemPrototype>
@end

@interface LVEffectPanelItem (Sticker)
@property(nonatomic, copy, readonly, nullable) NSString *stickerTrackThumbnailURL;
@property(nonatomic, copy, readonly, nullable) NSString *stickerPreviewCoverURL;
@end

NS_ASSUME_NONNULL_END
