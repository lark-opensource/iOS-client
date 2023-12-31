//
//  IESLiveResouceBundle+Loader.h
//  Pods
//
//  Created by Zeus on 2016/12/23.
//
//

#import "IESLiveResouceBundle.h"

@interface IESLiveResouceBundle (Loader)

/**
 遍历Main Bundle，获取所有category相符的bundle名称列表
 
 @param category 资源包模块名
 */
+ (NSArray <NSString *>*)loadBundleNamesWithCategory:(NSString *)category;

/**
 遍历Main Bundle，自动选择一个category相符的资源包。
 
 如果有多个category匹配的资源包，在资源包的继承链中，随机返回一个叶子节点。
 
 @param category 资源包模块名
 */
+ (IESLiveResouceBundle *)loadAssetBundleWithCategory:(NSString *)category;

@end
