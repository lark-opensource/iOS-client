//
//  CJPayTopLoadingItem.h
//  CJPay
//
//  Created by 尚怀军 on 2019/11/12.
//

#import <Foundation/Foundation.h>
#import "CJPayLoadingManager.h"
#import "CJPayTimerManager.h"
#import "CJPayBaseLoadingItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayTopLoadingItem : CJPayBaseLoadingItem <CJPayAdvanceLoadingProtocol>

@property (nonatomic, strong) CJPayTimerManager *timerManager;

- (BOOL)setTimer;

@end

NS_ASSUME_NONNULL_END
