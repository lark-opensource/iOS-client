//
//  BDXLynxDialerKeyListener.m
//  XElement
//
//  Created by zhangkaijie on 2021/6/7.
//

#import "BDXLynxDialerKeyListener.h"
#import <Foundation/Foundation.h>

static NSString* const CHARACTERS = @"0123456789#*+_(),/N. ;";

@implementation BDXLynxDialerKeyListener

- (instancetype)init {
  self = [super init];
  if (self) {
    //
  }
  return self;
}

- (NSInteger)getInputType {
  return TYPE_CLASS_PHONE;
}

- (NSString*)getAcceptedChars {
  return CHARACTERS;
}

@end
