//
//  IWKWebViewPluginHelper.m
//  BDWebCore
//
//  Created by li keliang on 2019/7/19.
//

#import "IWKWebViewPluginHelper.h"

@implementation IWKWebViewPluginHelper

+ (IWKPluginHandleResultType)runPlugins:(NSArray *)plugins
                    withHandleBlock:(__nullable id (^)(id plugin, NSDictionary *extra))handleBlock
{
    return [self runPlugins:plugins extra:nil withHandleBlock:handleBlock];
}

+ (IWKPluginHandleResultType)runPlugins:(NSArray *)plugins
                              extra:(NSDictionary * _Nullable)extra
                    withHandleBlock:(__nullable id (^)(id plugin, NSDictionary *extra))handleBlock
{
    __block IWKPluginHandleResultType returnValue = nil;
    [plugins enumerateObjectsUsingBlock:^(IWKPluginObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IWKPluginHandleResultType result = handleBlock(obj, extra);
        if (!result) {
            return;
        }
        
        if ([result isKindOfClass:IWKPluginHandleResultObj.class] && result.flow == IWKPluginHandleResultFlowBreak) {
            returnValue = result;
            *stop = YES;
        } else if (![result isKindOfClass:IWKPluginHandleResultObj.class]) {
            returnValue = IWKPluginHandleResultWrapValue(result);
            *stop = YES;
        }
    }];
    return returnValue;
}

+ (void)duplicateCheck:(id<IWKPluginObject>)plugin inContainer:(NSArray<id<IWKPluginObject>> *)container
{
    __block id duplicatePlugin = nil;
    [container enumerateObjectsUsingBlock:^(id<IWKPluginObject> loadedPlugin, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([plugin.uniqueID isEqualToString:loadedPlugin.uniqueID]) {
            duplicatePlugin = loadedPlugin;
            *stop = YES;
        }
    }];
    
    if (duplicatePlugin) {
        NSString *reason = [NSString stringWithFormat:@"You attempt to load the same uniqueID('%@') plugin.", plugin.uniqueID];
        @throw [NSException exceptionWithName:@"BDWebDuplicatePluginsException" reason:reason userInfo:nil];
    }
}

@end
