//
//  IESLiveResouceManager.h
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import <Foundation/Foundation.h>
#import "IESLiveResouceBundle.h"

@protocol IESLiveResouceManagerProtocol <NSObject>

/**
 创建一个资源解析器，供子类集成并进行初始化，不要直接调用这个方法，参见`instanceWithAssetBundle`
 
 @param assetBundle 所属资源包
 
 @param type 针对的资源类型
 */
- (instancetype)initWithAssetBundle:(IESLiveResouceBundle *)assetBundle type:(NSString *)type;

/**
 获取一个资源
 
 @param key 资源key
 */
- (id)objectForKey:(NSString *)key;

@end

@interface IESLiveResouceManager<ObjectType> : NSObject<IESLiveResouceManagerProtocol>

/**
 所属的资源包
 */
@property (nonatomic, weak, readonly) IESLiveResouceBundle *assetBundle;


/**
 资源解析器处理的文件类型
 */
@property (nonatomic, readonly) NSString *type;

/**
 获取一个资源
 
 @param key 资源key
 */
- (ObjectType)objectForKey:(NSString *)key;

@end

@interface IESLiveResouceManager (Type)

/**
 注册资源的解析器，如果对同一个类型注册多次，以最后一次为准
 
 @param class 解析器的class
 
 @param type 针对的资源类型
 */
+ (void)registerAssetManagerClass:(Class)class forType:(NSString *)type;

/**
 创建一个资源解析器，依赖于`registerAssetManagerClass`所注册的管理器map
 
 @param assetBundle 所属的资源包
 
 @param type 针对的资源类型
 */
+ (instancetype)instanceWithAssetBundle:(IESLiveResouceBundle *)assetBundle forType:(NSString *)type;

@end
