//
//  CJPayShareProtocol.h
//  CJPay
//
//  Created by liutianyi on 2022/8/18.
//

#ifndef CJPayShareProtocol_h
#define CJPayShareProtocol_h

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayShareProtocol <NSObject>

- (void)showSharePanel:(NSDictionary *)param;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayShareProtocol_h */
