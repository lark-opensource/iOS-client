//
//  BDLComponetModule.m
//  BDLynx
//
//  Created by  wanghanfeng on 2020/3/3.
//

#import "BDLComponetModule.h"
#import "BDLSDKManager.h"
#import "BDLynxUIATag.h"
#import "LynxComponentRegistry.h"

@implementation BDLComponetModule

LYNX_LOAD_LAZY(BDL_BIND_SERVICE(self.class, BDLComponentInternalProtocol);)

- (void (^)(void))registCustomUIComponent {
  return ^{
    [LynxComponentRegistry registerUI:[BDLynxUIATag class] withName:@"a"];
  };
}

@end
