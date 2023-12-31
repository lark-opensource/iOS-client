//
//  BDPKeyboardManager.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPKeyboardManager : NSObject

@property (nonatomic, assign) CGRect keyboardFrame;
@property (nonatomic, assign, getter=isKeyboardShow) BOOL keyboardShow;

+ (instancetype)sharedManager;

@end

NS_ASSUME_NONNULL_END
