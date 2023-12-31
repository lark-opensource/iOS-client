//
//  BDPPluginApplication.m
//  TTMicroApp
//
//  Created by 王浩宇 on 2019/1/26.
//

#import "BDPPluginApplication.h"
#import "BDPTaskManager.h"

@implementation BDPPluginApplication

#pragma mark - Initilize
/*-----------------------------------------------*/
//              Initilize - 初始化相关
/*-----------------------------------------------*/

+ (BDPJSBridgePluginMode)pluginMode
{
    return BDPJSBridgePluginModeLifeCycle;
}

#pragma mark - Function Implementation
/*-----------------------------------------------*/
//       Function Implementation - 方法实现
/*-----------------------------------------------*/

- (void)getMenuButtonBoundingClientRectWithParam:(NSDictionary *)param callback:(BDPJSBridgeCallback)callback engine:(BDPJSBridgeEngine)engine controller:(UIViewController *)controller
{
    OPAPICallback *apiCallback = BDP_API_CALLBACK;
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:engine.uniqueID];
    
    // Get ToolBar Rect
    CGRect toolBarRect = [task.containerVC getToolBarRect];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@(toolBarRect.size.width) forKey:@"width"];
    [params setValue:@(toolBarRect.size.height) forKey:@"height"];
    [params setValue:@(toolBarRect.origin.x) forKey:@"left"];
    [params setValue:@(toolBarRect.origin.y) forKey:@"top"];
    [params setValue:@(toolBarRect.origin.x + toolBarRect.size.width) forKey:@"right"];
    [params setValue:@(toolBarRect.origin.y + toolBarRect.size.height) forKey:@"bottom"];

    apiCallback.addMap([params copy]).invokeSuccess();
}

@end
