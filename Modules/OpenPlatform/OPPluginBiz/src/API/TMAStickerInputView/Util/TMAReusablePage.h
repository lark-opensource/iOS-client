//
//  TMAReusablePage.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/15.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TMAReusablePage <NSObject>

@property (nonatomic, strong) NSString *reuseIdentifier;

@property (nonatomic) BOOL nonreusable;

@property (nonatomic) BOOL focused;

- (void)prepareForReuse;

@optional

- (void)didBecomeFocusPage;
- (void)didResignFocusPage;

@end
