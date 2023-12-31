//
//  BridgeViewMarker.m
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/7.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDBridgeViewMarker.h"
#import <objc/runtime.h>

static const NSInteger TAG_NOTFOUND = -1;
static NSInteger sLastId = 0;

@interface BridgeTag : NSObject
@property(assign , nonatomic) NSInteger tagId;
@end

@implementation BridgeTag
- (instancetype)init {
  if (self = [super init]) {
    self.tagId = sLastId++;
  }
  return self;
}
@end


@interface NSObject (BridgeTag)
- (BridgeTag *)bridgeTag;
- (void)setBridgeTag:(BridgeTag *)tag;
@end

@implementation NSObject (BridgeTag)
- (BridgeTag *)bridgeTag {
  return objc_getAssociatedObject(self, _cmd);
}
- (void)setBridgeTag:(BridgeTag *)tag {
  objc_setAssociatedObject(self, @selector(bridgeTag), tag, OBJC_ASSOCIATION_RETAIN);
}
@end


@implementation BDBridgeViewMarker

+ (NSInteger)getBridgeId:(NSObject *)obj {
  BridgeTag *tag = [obj bridgeTag];
  if (tag) {
    return tag.tagId;
  }
  return TAG_NOTFOUND;
}

+ (NSInteger)generateBridgeIfNeed:(NSObject *)obj {
  if (obj) {
    BridgeTag *tag = [obj bridgeTag];
    if (!tag) {
      tag = [[BridgeTag alloc] init];
      [obj setBridgeTag:tag];
    }
    return tag.tagId;
  }
  return TAG_NOTFOUND;
}

@end
