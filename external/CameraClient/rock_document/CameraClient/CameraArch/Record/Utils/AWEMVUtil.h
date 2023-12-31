//
//  AWEMVUtil.h
//  Pods
//
//  Created by zhangchengtao on 2019/4/17.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@class VEEditorSession;

@interface AWEMVUtil : NSObject

/// Befor config a new created VEEditorSession instance for mv use, call this method first!
+ (BOOL)shouldConfigPlayerWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel;

+ (BOOL)precheckShouldCreateMVPlayerWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel;

+ (void)preprocessPublishViewModelForMVPlayer:(AWEVideoPublishViewModel *)publishViewModel;

@end

NS_ASSUME_NONNULL_END
