//
//  DVELiteStickerBar.h
//
//  Created by pengzhenhuan on 2022/1/11.
//

#import <Foundation/Foundation.h>
#import "DVEBaseView.h"
#import "DVEEditBoxPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVELiteStickerBar : DVEBaseView

@property (nonatomic, copy) dispatch_block_t dismissBlock;

@property (nonatomic, assign) CGFloat panelHeight;

@property (nonatomic, copy) void(^applyBlock)(NSString *);

- (instancetype)initWithFrame:(CGRect)frame
                    vcContext:(DVEVCContext *)vcContext;

@end

NS_ASSUME_NONNULL_END
