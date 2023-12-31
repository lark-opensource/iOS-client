//
//  ACCViewModel.h
//  Pods
//
//  Created by leo on 2020/2/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESServiceProvider;
@class AWEVideoPublishViewModel;

@protocol ACCViewModel <NSObject>

@property (nonatomic, strong) id inputData;
@property (nonatomic, weak) AWEVideoPublishViewModel *repository;
@property (nonatomic, weak) id<IESServiceProvider> serviceProvider;

@optional
- (void)onCleared;

@end

NS_ASSUME_NONNULL_END
