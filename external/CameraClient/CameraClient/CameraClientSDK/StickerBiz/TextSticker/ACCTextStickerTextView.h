//
//  ACCTextStickerTextView.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/17.
//

#import "ACCEditPageTextView.h"
#import <CreationKitArch/ACCEditPageLayoutManager.h>
#import "ACCEditPageTextStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCTextStickerTextView : ACCEditPageTextView

@property (nonatomic, strong, readonly) ACCEditPageLayoutManager *acc_layoutManager;
@property (nonatomic, strong, readonly) ACCEditPageTextStorage *acc_textStorage;

- (void)drawBackgroundWithFillColor:(UIColor *)fillColor;

@end

NS_ASSUME_NONNULL_END
