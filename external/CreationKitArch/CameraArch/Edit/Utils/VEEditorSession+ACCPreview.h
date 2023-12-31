//
//  VEEditorSession+ACCPreview.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/18.
//

#import <TTVideoEditor/VEEditorSession.h>

NS_ASSUME_NONNULL_BEGIN

@interface VEEditorSession (ACCPreview)

@property (nonatomic, assign) CGRect acc_playerFrame;
@property (nonatomic, assign) BOOL acc_stickerEditMode;

- (void)acc_continuePlay;

- (void)acc_setStickerEditMode:(BOOL)mode;

@end

NS_ASSUME_NONNULL_END
