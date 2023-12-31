//
//  LynxTextShadow.m
//  Lynx
//
//  Created by bytedance on 2020/2/20.
//

#import "LynxConverter+NSShadow.h"
#import "LynxLog.h"

@implementation LynxConverter (NSShadow)
+ (NSShadow *)toNSShadow:(NSArray<LynxBoxShadow *> *)shadowArr {
  if (!shadowArr || [shadowArr count] <= 0) {
    return nil;
  }
  // lynx only support one shadow.
  LynxBoxShadow *boxShadow = shadowArr[0];
  NSShadow *shadow = [[NSShadow alloc] init];
  shadow.shadowOffset = CGSizeMake(boxShadow.offsetX, boxShadow.offsetY);
  shadow.shadowBlurRadius = boxShadow.blurRadius;
  shadow.shadowColor = boxShadow.shadowColor;
  return shadow;
}

@end
