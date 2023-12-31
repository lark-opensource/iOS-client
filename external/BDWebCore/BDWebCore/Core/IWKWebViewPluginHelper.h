//
//  IWKWebViewPluginHelper.h
//  BDWebCore
//
//  Created by li keliang on 2019/7/19.
//

#import <Foundation/Foundation.h>
#import <BDWebCore/IWKPluginObject.h>

NS_ASSUME_NONNULL_BEGIN

@interface IWKWebViewPluginHelper<__covariant ObjectType> : NSObject

+ (IWKPluginHandleResultType)runPlugins:(NSArray<ObjectType> *)plugins
                    withHandleBlock:(__nullable id (^)(ObjectType plugin, NSDictionary *extra))handleBlock;

+ (IWKPluginHandleResultType)runPlugins:(NSArray<ObjectType> *)plugins
                              extra:(NSDictionary * _Nullable)extra
                    withHandleBlock:(__nullable id (^)(ObjectType plugin, NSDictionary *extra))handleBlock;

+ (void)duplicateCheck:(id<IWKPluginObject>)plugin inContainer:(NSArray<id<IWKPluginObject>> *)container;

@end

typedef IWKWebViewPluginHelper<IWKPluginObject *> IWKPluginHelper;

NS_ASSUME_NONNULL_END

