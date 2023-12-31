//
//  TMASticker.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/28.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMAEmoji.h"

@interface TMASticker : NSObject

@property (nonatomic, strong) NSString *coverImageName;
@property (nonatomic, strong) NSArray<TMAEmoji *> *emojis;

@end
