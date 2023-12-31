//
//  IESLiveResouceBundleGroup.h
//  Pods
//
//  Created by Zeus on 2016/12/23.
//
//

#import "IESLiveResouceBundle.h"

@interface IESLiveResouceBundleGroup : IESLiveResouceBundle

/**
 将多个资源包组合成一个逻辑上的资源包；
 
 获取一个资源时，会依次从这些资源包及其父节点获取。
 
 @param bundleNames 资源包名称
 */
- (instancetype)initWithBundleNames:(NSArray<NSString *> *)bundleNames;

- (instancetype)initWithBundles:(NSArray<IESLiveResouceBundle *> *)bundles;

@end
