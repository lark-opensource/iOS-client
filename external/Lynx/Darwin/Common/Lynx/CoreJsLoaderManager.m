//
//  CoreJsLoaderManager.m
//  Lynx
//
//  Created by admin on 2020/8/28.
//

#import "CoreJsLoaderManager.h"
#import <Foundation/Foundation.h>

@implementation CoreJsLoaderManager

static CoreJsLoaderManager* _instance = nil;

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init];
  });
  return _instance;
}

@end
