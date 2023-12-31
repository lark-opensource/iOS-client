//
//  BDXElementMonitorDelegate.h
//  BDXElement
//
//  Created by Lizhen Hu on 2020/11/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LynxView;

@protocol BDXElementMonitorDelegate <NSObject>

@optional

- (void)reportWithEventName:(NSString *)eventName
                   lynxView:(LynxView *)lynxView
                     metric:(nullable NSDictionary *)metric
                   category:(nullable NSDictionary *)category
                      extra:(nullable NSDictionary *)extra;

@end

@protocol BDXElementLottieDelegate <BDXElementMonitorDelegate>
@end

NS_ASSUME_NONNULL_END
