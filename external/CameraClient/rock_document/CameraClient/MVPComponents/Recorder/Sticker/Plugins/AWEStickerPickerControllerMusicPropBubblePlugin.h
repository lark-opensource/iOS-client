//
//  AWEStickerPickerControllerMusicPropBubblePlugin.h
//  CameraClient-Pods-Aweme
//
//  Created by Lincoln on 2020/12/11.
//

#import <Foundation/Foundation.h>
#import "AWEStickerPickerControllerPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCPropViewModel, ACCRecordSelectPropViewModel;
@protocol ACCRecorderViewContainer;

typedef void(^ACCInsertRecommendPropToHotFirstBlock)(IESEffectModel *);

@interface AWEStickerPickerControllerMusicPropBubblePlugin : NSObject <AWEStickerPickerControllerPluginProtocol>

- (instancetype)initWithViewModel:(ACCPropViewModel *)viewModel
              selectPropViewModel:(ACCRecordSelectPropViewModel *)selectPropViewModel
                    viewContainer:(id<ACCRecorderViewContainer>)viewContainer
      insertRecommendPropTopBlock:(ACCInsertRecommendPropToHotFirstBlock)insertPropBlock;

@property (nonatomic, copy) void (^applyPropCallback)(IESEffectModel *prop);
@property (nonatomic, assign) BOOL enableInPropPickerPanel;
- (void)onPropPickerPanelDidShow;
- (void)tryToShowBubble;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
