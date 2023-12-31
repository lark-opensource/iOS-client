//
//  BDWebKitMainFrameModel.m
//  Pods
//
//  Created by bytedance on 4/15/22.
//

#import "BDWebKitMainFrameModel.h"

NSString *const kBDWMainFrameReceiveLoadRequestEvent = @"bdw_mainFrameReceivedLoadRequest";
NSString *const kBDWMainFrameStartProvisionalNavigationEvent = @"bdw_mainFrameStartProvisionalNavigation";
NSString *const kBDWMainFrameReceiveServerRedirectCount = @"bdw_mainFrameReceiveServerRedirectCount";
NSString *const kBDWMainFrameReceiveServerRedirectForProvisionalNavigationEvent = @"bdw_mainFrameReceiveServerRedirectForProvisionalNavigation";
NSString *const kBDWMainFrameReceiveNavigationResponseEvent = @"bdw_mainFrameReceiveNavigationResponse";
NSString *const kBDWMainFrameCommitNavigationEvent = @"bdw_mainFrameCommitNavigation";
NSString *const kBDWMainFrameFinishNavigationEvent = @"bdw_mainFrameFinishNavigation";

@implementation BDWebKitMainFrameModel

@synthesize loadFinishWithLocalData;

@end
