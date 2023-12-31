//
//  CJPayLifeCycleObserver.h
//  Aweme
//
//  Created by wangxinhua on 2023/7/8.
//

#ifndef CJPayLifeCycleObserver_h
#define CJPayLifeCycleObserver_h

@protocol CJPayLifeCycleObserver <NSObject>

- (void)beginPay;
- (void)endPay;

@end

#endif /* CJPayLifeCycleObserver_h */
