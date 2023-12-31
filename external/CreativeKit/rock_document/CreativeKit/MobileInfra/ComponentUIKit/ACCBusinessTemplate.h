//
//  ACCBusinessTemplate.h
//  CameraClient
//
//  Created by Liu Deping on 2020/7/10.
//

#import <Foundation/Foundation.h>

typedef Class ACCFeatureComponentClass;
typedef Class ACCFeatureComponentPluginClass;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCBusinessTemplate <NSObject>

- (NSArray<ACCFeatureComponentClass> *)componentClasses;
@optional
// Todo: the required component plugins do not need to be processed manually. Only the optional subcomponents are returned here
- (NSArray<ACCFeatureComponentPluginClass> *)componentPluginClasses;

@end


NS_ASSUME_NONNULL_END
