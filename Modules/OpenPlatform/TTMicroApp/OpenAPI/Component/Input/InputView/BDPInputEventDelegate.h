//
//  BDPInputEventDelegate.h
//  TTMicroApp
//
//  Created by xiongmin on 2022/5/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDPInputEventDelegate <NSObject>

- (void)fireInputEvent:(NSString *)event data:(NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END
