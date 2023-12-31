//
//  ACCTextStickerHandlerSpeakerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/5.
//

#import <Foundation/Foundation.h>

#import "ACCTextStickerView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCTextStickerHandlerSpeakerModel : NSObject

@property (nonatomic, weak, nullable, readonly) ACCTextStickerView *editingTextStickerView; // indicate the text sticker view which is being used to choose tts sound effects
@property (nonatomic, weak, nullable, readonly) UIView<ACCStickerProtocol> *editingTextStickerTimeView; // the one before entering edit view
@property (nonatomic, strong, nullable, readonly) AWETextStickerReadModel *modelBeforeEditing; // readonly, its content shouldn't be changed
@property (nonatomic, strong, nullable, readonly) AWETextStickerReadModel *modelWhileEditing;

- (void)updateBeforeEditingWithTextStickerView:(ACCTextStickerView *)editingTextStickerView;
- (void)updateModelWhileEditing:(NSString *)audioPath speakerID:(NSString *)speakerID;
- (void)reset; // set all the properties to nil

@end

NS_ASSUME_NONNULL_END
