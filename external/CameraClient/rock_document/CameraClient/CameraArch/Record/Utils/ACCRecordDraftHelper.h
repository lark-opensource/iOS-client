//
//  ACCRecordDraftHelper.h
//  Pods
//
//  Created by songxiangwu on 2019/8/16.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCRecordDraftHelper : NSObject

+ (void)saveBackupWithRepository:(AWEVideoPublishViewModel *)repository;
+ (void)saveBackupWithPublishModel:(AWEVideoPublishViewModel *)publishModel video:(ACCEditVideoData *)video;

@end

NS_ASSUME_NONNULL_END
