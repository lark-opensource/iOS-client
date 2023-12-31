//
//  TMATextBackedString.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/17.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * _Nonnull const TMATextBackedStringAttributeName;

@interface TMATextBackedString : NSObject <NSCoding, NSCopying>

@property (nullable, nonatomic, copy) NSString *string;

+ (nullable instancetype)stringWithString:(nullable NSString *)string;

@end
