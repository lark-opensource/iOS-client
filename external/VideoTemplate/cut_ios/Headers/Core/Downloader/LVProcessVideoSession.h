//
//  LVProcessVideoSession.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/16.
//

#import <Foundation/Foundation.h>
#import "LVMediaDraft.h"
#import "LVPreprocessSession.h"

NS_ASSUME_NONNULL_BEGIN

@class LVTemplateDataManager;

@interface LVProcessVideoSession : LVPreprocessSession

- (instancetype)initWithDataManager:(LVTemplateDataManager *)dataManager;

@end

NS_ASSUME_NONNULL_END
