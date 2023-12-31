//
//  AWEStudioFeedbackRecorderConsts.h
//  Pods
//
//  Created by 赖霄冰 on 2019/7/26.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AWEStudioFeedBackStatus) {
    AWEStudioFeedBackStatusStart,
    AWEStudioFeedBackStatusSuccess,
    AWEStudioFeedBackStatusFail,
    AWEStudioFeedBackStatusCancel,
};

static NSString *const ACC_FEEDBACK_KEY_LABEL = @"label";
static NSString *const ACC_FEEDBACK_KEY_CODE = @"code";
static NSString *const ACC_FEEDBACK_KEY_MESSAGE = @"message";
static NSString *const ACC_FEEDBACK_KEY_STATUS = @"status";
