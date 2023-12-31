//
//  TTBridgeAuthDebugRowPlugin.m
//  TTBridgeUnify
//
//  Created by liujinxing on 2020/8/13.
//

#import "TTBridgeAuthDebugRowPlugin.h"
#import "TTBridgeAuthDebugViewController.h"

@implementation TTBridgeAuthDebugRowPlugin

+ (void)loadPlugin {
    TTLoadDebugRowPluginMethod
    [[TTDebugPluginManager defaultManager] loadRowPlugin:({
        TTBridgeAuthDebugRowPlugin *plugin = TTBridgeAuthDebugRowPlugin.new;
        STTableViewCellItem *jsbAuthDebugItem = [[STTableViewCellItem alloc] initWithTitle:@"Piper Gecko Auth Debug" target:plugin action:@selector(_jsbAuthDebug)];
        plugin.cellItem = jsbAuthDebugItem;
        plugin;
    })];
}

- (void)_jsbAuthDebug {
    [self.viewController.navigationController pushViewController:[[TTBridgeAuthDebugViewController alloc] init]
                                            animated:YES];
}

@end
