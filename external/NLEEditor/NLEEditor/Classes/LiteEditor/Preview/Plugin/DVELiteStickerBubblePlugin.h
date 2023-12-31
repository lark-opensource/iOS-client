//
//  DVELiteStickerBubblePlugin.h
//  Pods
//
//  Created by pengzhenhuan on 2022/1/14.
//

#import <UIKit/UIKit.h>
#import "DVEPreviewPluginProtocol.h"
#import "DVEEditStickerBubbleManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVELiteStickerBubblePlugin : NSObject<DVEPreviewPluginProtocol>

- (instancetype)initWithName:(NSString *)name
                 bubbleItems:(NSArray<DVEEditStickerBubbleItem *> *)bubbleItems;

- (void)updateTargetView:(UIView *)targetView;

- (void)bubbleWillHide;

@end

NS_ASSUME_NONNULL_END
