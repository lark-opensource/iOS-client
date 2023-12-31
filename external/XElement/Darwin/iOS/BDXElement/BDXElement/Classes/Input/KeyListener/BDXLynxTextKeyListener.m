//
//  BDXLynxTextKeyListener.m
//  XElement
//
//  Created by zhangkaijie on 2021/6/7.
//

#import "BDXLynxTextKeyListener.h"
#import <Foundation/Foundation.h>

@implementation BDXLynxTextKeyListener

- (instancetype)init {
  self = [super init];
  if (self) {
    //
  }
  return self;
}

- (NSInteger)getInputType {
  return TYPE_CLASS_TEXT;
}

- (NSString *)filter:(NSString *)source start:(NSInteger)start end:(NSInteger)end dest:(NSString *)dest dstart:(NSInteger)dstart dend:(NSInteger)dend {
    return source;
}

@end
