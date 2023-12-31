//
//  BDXElementToastDelegate.h
//  BDXElement
//
//  Created by miner on 2020/7/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXElementToastDelegate <NSObject>

- (void)show:(NSString *)message;
- (void)showError:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
