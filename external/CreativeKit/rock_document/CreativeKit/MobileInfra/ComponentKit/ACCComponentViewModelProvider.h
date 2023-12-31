//
//  ACCComponentViewModelProvider.h
//  CameraClient
//
//  Created by Liu Deping on 2020/7/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol ACCViewModel;

@protocol ACCComponentViewModelProvider <NSObject>

- (__kindof id<ACCViewModel>)getViewModel:(Class)viewModelClass;

@end

NS_ASSUME_NONNULL_END
