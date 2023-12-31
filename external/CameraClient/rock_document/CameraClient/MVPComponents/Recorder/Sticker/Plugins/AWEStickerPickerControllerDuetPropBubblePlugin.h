//
//  AWEStickerPickerControllerDuetPropBubblePlugin.h
//  CameraClient-Pods-Aweme
//
//  Created by zhuopeijin on 2021/3/23.
//

#import <Foundation/Foundation.h>
#import "AWEStickerPickerControllerPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCPropViewModel;
@protocol ACCRecorderViewContainer;

@interface AWEStickerPickerControllerDuetPropBubblePlugin : NSObject<AWEStickerPickerControllerPluginProtocol>

@property (nonatomic, copy) void (^additionalApplyPropBlock)(IESEffectModel *prop);

- (instancetype)initWithViewModel:(ACCPropViewModel *)viewModel
                     bubbleEffect:(IESEffectModel *) bubbleEffect
                    viewContainer:(id<ACCRecorderViewContainer>)viewContainer;

- (void)tryToShowBubble;

@end

NS_ASSUME_NONNULL_END
