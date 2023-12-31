//
//  DVELiteClipPanel.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/7.
//

#import <UIKit/UIKit.h>
#import "DVEBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVELiteClipPanel : DVEBaseView

@property (nonatomic, copy) NSString *titleText;

@property (nonatomic, copy) NSString *infoText;

@property (nonatomic, assign) CGFloat panelHeight;

@property (nonatomic, copy) dispatch_block_t closeBlock;

@property (nonatomic, copy) dispatch_block_t doneBlock;

- (instancetype)initWithFrame:(CGRect)frame
                    vcContext:(DVEVCContext *)vcContext NS_REQUIRES_SUPER;

- (void)updateFunctionalButtonsEnable:(BOOL)enable;

- (void)onApplicationDidChangeStatusBarOrientation:(NSNotification *)notifaction NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
