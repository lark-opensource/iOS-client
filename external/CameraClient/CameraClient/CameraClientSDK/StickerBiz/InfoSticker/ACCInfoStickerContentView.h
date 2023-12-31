//
//  ACCInfoStickerContentView.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/9/14.
//

#import "ACCStickerEditContentProtocol.h"
#import "ACCInfoStickerConfig.h"

@class IESInfoStickerProps;
@protocol ACCEditServiceProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface ACCInfoStickerContentView : UIView <ACCStickerEditContentProtocol>

@property (nonatomic, strong) ACCInfoStickerConfig *config;

@property (nonatomic, strong) IESInfoStickerProps *stickerInfos;

@property (nonatomic, assign) NSInteger stickerId;

@property (nonatomic, weak  ) id<ACCEditServiceProtocol> editService;

// show author
@property (nonatomic, assign) BOOL shouldShowAuthor;
@property (nonatomic, copy) NSString *authorName;
@property (nonatomic, weak) UIView *hintView;

@property (nonatomic, assign) BOOL isCustomUploadSticker;

@property (nonatomic, copy  ) void(^didCancledPinCallback)(ACCInfoStickerContentView *theView);

- (void)didCancledPin;

@end

NS_ASSUME_NONNULL_END
