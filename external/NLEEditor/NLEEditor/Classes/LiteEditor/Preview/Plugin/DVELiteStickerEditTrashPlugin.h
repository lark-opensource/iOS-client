//
//  DVELiteStickerEditTrashPlugin.h
//  NLEEditor
//
//  Created by pengzhenhuan on 2022/1/14.
//

#import <UIKit/UIKit.h>
#import "DVEPreviewPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVELiteStickerEditTrashDelegate <NSObject>

- (void)editTrashWillShow;

- (void)editTrashWillHide;

- (void)editTrashDidFinishWithId:(NSString *)slotId;

- (UIView *)bindViewForEditTrash;

@end

@interface DVELiteStickerEditTrashPlugin : UIView<DVEPreviewPluginProtocol>

@property (nonatomic, weak) id<DVELiteStickerEditTrashDelegate> delegate;

- (void)adjustTextSizeIfNeed;

@end

NS_ASSUME_NONNULL_END
