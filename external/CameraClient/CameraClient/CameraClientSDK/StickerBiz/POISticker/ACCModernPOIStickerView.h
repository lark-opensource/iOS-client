//
//  ACCModernPOIStickerView.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/9/20.
//

#import "ACCStickerEditContentProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerPlayerApplying;
@class ACCPOIStickerModel;

@protocol ACCModernPOIStickerViewHelperProtocol <NSObject>

- (id<ACCStickerPlayerApplying>)currentPlayer;

@end

@interface ACCModernPOIStickerView : UIView <ACCStickerEditContentProtocol>

@property (nonatomic, assign) NSInteger stickerId;

@property (nonatomic, strong) NSString *poiIdentifier;

@property (nonatomic, strong) ACCPOIStickerModel *model;

@property (nonatomic, weak) id<ACCModernPOIStickerViewHelperProtocol> helper;

@end

NS_ASSUME_NONNULL_END
