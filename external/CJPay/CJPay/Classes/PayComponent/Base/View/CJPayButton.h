//
//  CJPayButton.h
//  CJPay
//
//  Created by 王新华 on 2018/12/10.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayButton : UIButton

@property (nonatomic, assign) NSTimeInterval cjEventInterval;
@property (nonatomic, strong) NSNumber *cjEventUnavailable;
@property (nonatomic, assign) BOOL disableHightlightState;

@end

NS_ASSUME_NONNULL_END
