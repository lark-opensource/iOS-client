//
//  CJPayBinaryAdapter.h
//  CJPay
//
//  Created by 王新华 on 2019/5/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayManagerAdapterDelegate <NSObject>

- (void)closePayDesk;

- (void)closePayDeskWithCompletion:(void (^)(BOOL))completion;

@end

@protocol CJPayHomeBizAdapterDelegate <NSObject>

- (NSDictionary *_Nullable)getPayInfoDic;

@end

// 二进制化的中间层，用来处理数据共享，页面通信
@interface CJPayBinaryAdapter : NSObject

+ (instancetype)shared;

@property (nonatomic, weak) id<CJPayManagerAdapterDelegate> managerDelegate;
@property (nonatomic, weak) id<CJPayHomeBizAdapterDelegate> confirmPresenterDelegate;

@end

NS_ASSUME_NONNULL_END
