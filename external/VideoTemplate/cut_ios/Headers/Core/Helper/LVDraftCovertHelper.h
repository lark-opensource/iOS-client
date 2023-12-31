//
//  LVDraftCovertHelper.h
//  VideoTemplate
//
//  Created by mmdoor on 2021/3/31.
//

#import <Foundation/Foundation.h>
#import "LVDraftModels.h"
NS_ASSUME_NONNULL_BEGIN

@interface LVDraftCovertHelper : NSObject

+ (LVCoverDraft *)covertLVMediaDraft:(LVMediaDraft *)draft;
+ (LVMediaDraft *)covertLVCoverDraft:(LVCoverDraft *)coverDraft;

@end

NS_ASSUME_NONNULL_END
