//
//  ACCEditorDraftService.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/5/18.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditorDraftService <NSObject>

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

- (void)saveDraftIfNecessary;

- (void)removePublishFailedDraft;

- (void)hadBeenModified;

- (void)saveDraftEnterNextVC;

@end

NS_ASSUME_NONNULL_END
