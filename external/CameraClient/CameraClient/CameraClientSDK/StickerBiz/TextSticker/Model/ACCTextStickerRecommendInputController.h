//
//  ACCTextStickerRecommendInputController.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/7/26.
//

#import <Foundation/Foundation.h>
#import "AWEModernTextToolBar.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCTextStickerRecommendItem, ACCTextStickerView, AWEModernTextToolBar, AWEVideoPublishViewModel;

@interface ACCTextStickerRecommendInputController : NSObject

@property (nonatomic, weak) AWEModernTextToolBar *toolBar;
@property (nonatomic, assign) BOOL fromTextMode;

- (instancetype)initWithStickerView:(ACCTextStickerView *)stickerView publishViewModel:(AWEVideoPublishViewModel *)publishViewModel;

- (void)didSelectRecommendTitle:(NSString *)title group:(nullable NSString *)group;
- (void)didShowRecommendTitle:(NSString *)title group:(nullable NSString *)group;
- (void)didSelectLibGroup:(NSString *)group;
- (void)didExitLibPanel:(BOOL)save;
- (void)didSelectKeyboardInput:(NSRange)range;
- (void)resetToContent:(NSString *)content;

- (void)switchInputMode:(BOOL)libMode;
- (void)trackForEnterLib:(BOOL)directEnter;

@end

NS_ASSUME_NONNULL_END
