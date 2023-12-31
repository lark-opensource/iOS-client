//
//  DVELiteTextBar.h
//  Pods
//
//  Created by pengzhenhuan on 2022/1/19.
//

#import "DVEBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVELiteTextColorStyleModel : NSObject

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, copy) dispatch_block_t actionBlock;

- (instancetype)initWithImage:(UIImage *)image
                  actionBlock:(dispatch_block_t)actionBlock;

@end

@interface DVELiteTextBar : DVEBaseView

@property (nonatomic, copy) dispatch_block_t dismissBlock;

@property (nonatomic, copy) void(^applyBlock)(NSString *);

@property (nonatomic, copy) NSString *textSlotId;

- (instancetype)initWithFrame:(CGRect)frame
                    vcContext:(DVEVCContext *)vcContext;


@end

NS_ASSUME_NONNULL_END
