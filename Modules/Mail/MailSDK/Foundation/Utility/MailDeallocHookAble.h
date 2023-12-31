//
//  MailDeallocHookAble.h
//  MailSDK
//
//  Created by tefeng liu on 2021/3/18.
//

#import <Foundation/Foundation.h>

@class MailDeallocHookAble;
typedef void (^MailDeallocBlock)(MailDeallocHookAble *object);

@interface MailDeallocHookAble : NSObject

@property (nonatomic, copy, nullable) MailDeallocBlock lk_deallocAction;

@end
