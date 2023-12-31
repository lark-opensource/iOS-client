//
//  ACCViewModelStore.h
//  Pods
//
//  Created by leo on 2020/2/5.
//

#import <Foundation/Foundation.h>
#import "ACCViewModel.h"
#import "ACCComponentViewModelProvider.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCViewModelFactory;

@interface ACCViewModelContainer : NSObject <ACCComponentViewModelProvider>

- (instancetype)initWithFactory:(id<ACCViewModelFactory>)factory NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, copy) NSArray *viewModelList;

- (void)clear;

@end

NS_ASSUME_NONNULL_END
