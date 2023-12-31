//
//  CJPayStyleButton+Freeze.h
//  CJPay
//
//  Created by liyu on 2019/11/26.
//

#import "CJPayStyleButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayStyleButton (Freeze)

@property (nonatomic, strong) dispatch_source_t cjButtonFreezeTimer;

- (void)freezeFor:(NSInteger)totalInterval;

@end

NS_ASSUME_NONNULL_END
