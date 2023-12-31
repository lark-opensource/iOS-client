//
//  TTKitchenDebugRowPlugin.m
//  TTKitchen
//
//  Created by liujinxing on 2020/10/12.
//

#import "TTKitchenDebugRowPlugin.h"
#import "TTKitchenDebugViewController.h"

@implementation TTKitchenDebugRowPlugin

+ (void)loadPlugin {
    TTLoadDebugRowPluginMethod
    [[TTDebugPluginManager defaultManager] loadRowPlugin:({
        TTKitchenDebugRowPlugin *plugin = [[TTKitchenDebugRowPlugin alloc]init];
        STTableViewCellItem *kitchenDebugItem = [[STTableViewCellItem alloc] initWithTitle:@"TTKitchen 功能测试" target:plugin action:@selector(_kitchenTest)];
        plugin.cellItem = kitchenDebugItem;
        plugin;
    })];
}

- (void)_kitchenTest {
    [self.viewController.navigationController pushViewController:TTKitchenDebugViewController.new animated:YES];
}

- (NSUInteger)index {
    return 5;
}

- (NSUInteger)sectionIndex {
    return 0;
}

@end
