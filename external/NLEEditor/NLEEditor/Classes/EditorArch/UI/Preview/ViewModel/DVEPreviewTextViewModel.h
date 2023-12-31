//
//  DVEPreviewTextViewModel.h
//  NLEEditor
//
//  Created by pengzhenhuan on 2022/1/10.
//

#import <Foundation/Foundation.h>
#import "DVEPreviewStickerViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEPreviewTextViewModel : DVEPreviewStickerViewModel

- (void)showTextTemplateEditBoxIfNeedWithSlotID:(NSString *)slotId;

@end

NS_ASSUME_NONNULL_END
