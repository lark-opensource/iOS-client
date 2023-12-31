//
//  ACCPublishServiceMessage.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2021/3/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPublishServiceMessage <NSObject>

@optional

- (void)publishServiceWillSaveDraft;

- (void)publishServiceWillStart;

- (void)publishServiceTaskWillAppend;

- (void)publishServiceTaskDidAppend;

- (void)publishServiceDraftWillSave;

- (void)publishServiceDraftDidSave;

@end

NS_ASSUME_NONNULL_END
