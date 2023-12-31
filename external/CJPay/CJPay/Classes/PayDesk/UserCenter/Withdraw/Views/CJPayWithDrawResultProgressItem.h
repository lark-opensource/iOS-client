//
//  CJWithdrawResultProgressItem.h
//  CJPay
//
//  Created by liyu on 2019/10/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJWithdrawResultProgressItemState) {
    kCJWithdrawResultProgressItemStateSuccess = 0,
    kCJWithdrawResultProgressItemStateProcessing,
    kCJWithdrawResultProgressItemStateUpcoming,
    kCJWithdrawResultProgressItemStateFail
};

@interface CJPayWithDrawResultProgressItem : NSObject

@property (nonatomic, assign) BOOL isFirst;
@property (nonatomic, assign) BOOL isLast;
@property (nonatomic, assign) CJWithdrawResultProgressItemState state;
@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *timeText;

- (instancetype)initWithTitle:(NSString *)title
                      isFirst:(BOOL)isFirst
                       isLast:(BOOL)isLast;

@end

NS_ASSUME_NONNULL_END
