//
//  IESLiveResouceBundle.h
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class IESLiveResouceManager;

extern NSString * const kIESLiveResourceBundleDynamicKey;

@interface IESLiveResouceBundle : NSObject

/**
 继承自的资源包
 */
@property (nonatomic, readonly) IESLiveResouceBundle *parent;

/**
 资源包名称，xxx.bundle
 */
@property (nonatomic, readonly) NSString *bundleName;

@property (nonatomic, readonly) NSBundle *bundle;

/**
 bundle所属的bundle，mainBundle or framework
 */
@property (nonatomic, readonly) NSBundle *mainBundle;

/**
 模块、组件类别，定义在Info.plist中，例如“movie”
 */
@property (nonatomic, readonly) NSString *category;

/**
 assetType => assetManager
 */
@property (nonatomic, readonly) NSDictionary<NSString *,IESLiveResouceManager *> *assetManagers;

/**
 获取/创建一个资源包
 
 内部维护了一个`弱引用`的map保证同一个资源包不会被重复创建
 
 @param bundleName 资源包名称
 */
+ (instancetype)assetBundleWithBundleName:(NSString *)bundleName;
- (instancetype)initWithBundleName:(NSString *)bundleName;
- (instancetype)initWithBundlePath:(NSString *)bundlePath;
- (instancetype)initWithBundle:(NSBundle *)bundle;

/**
 从资源包中获取一个资源
 
 @param key 资源key
 
 @param type 资源类型，image、string、color等，每种资源类型对应bundle子目录的一个同名文件夹
 */
- (id)objectForKey:(NSString *)key type:(NSString *)type;


/**
 是否从assets里获取图片资源
 */

- (BOOL)isImageFromAssets;
@end

@interface IESLiveResouceBundle (Category)

/**
 指定category模块、组件使用bundleName资源包
 
 @param bundleName 资源包名称，如果bundle本身在动态库里，需要使用className/xxx.bundle
 
 @param category 模块、组件名称
 */
+ (void)useBundle:(NSString *)bundleName forCategory:(NSString *)category;

/**
 获取category模块、组件当前使用的资源包名称
 
 @param category 模块、组件名称
 */
+ (NSString *)assetBundleNameWithCategory:(NSString *)category;

/**
 指定动态绑定的bundleName资源包

 @param bundleName 资源包名称
 
 @param dynamicKey 动态资源包关键字 (关键字包含：dynamic)
 */
+ (void)useBundleName:(NSString *)bundleName forDynamicKey:(NSString *)dynamicKey;

/**
 动态获取指定定的关键字使用的资源包名称

 @param dynamicKey 动态资源包关键字 (关键字包含：dynamic)
 */
+ (NSString *)assetBundleNameWithDynamicKey:(NSString *)dynamicKey;
/**
 获取category模块、组件当前使用的资源包
 
 @param category 模块、组件名称
 */
+ (IESLiveResouceBundle *)assetBundleWithCategory:(NSString *)category;

@end
