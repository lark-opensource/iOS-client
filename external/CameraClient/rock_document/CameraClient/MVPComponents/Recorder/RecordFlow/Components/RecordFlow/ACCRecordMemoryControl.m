//
//  ACCRecordMemoryControl.m
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2021/4/13.
//

#import "ACCRecordMemoryControl.h"
#import "ACCCreativePathMessage.h"
#import "ACCVideoPublishProtocol.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCCreativePathConstants.h"
#import <CreativeKit/ACCMacros.h>
#import <HTSServiceKit/HTSMessageCenter.h>

@interface ACCRecordMemoryControl ()<ACCCreativePathMessage>

@property (nonatomic, assign) BOOL pureMode;

@end

@implementation ACCRecordMemoryControl

- (instancetype)init
{
    self = [super init];
    if (self) {
        REGISTER_MESSAGE(ACCCreativePathMessage, self);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restorePureMode:) name:ACCRecordBeofeWillAppearNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    UNREGISTER_MESSAGE(ACCCreativePathMessage, self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)logPureModeChange:(BOOL)state
{
    AWELogToolInfo2(@"effect", AWELogToolTagRecord, @"publish parallel, camera pure mode: %@", @(state));
}

#pragma mark - ACCCreativePathMessage
- (void)creativePathPageDidAppear:(ACCCreativePage)page
{
    if (!self.pureMode && page == ACCCreativePageEdit && [ACCVideoPublish() hasTaskExecuting]) {
        self.pureMode = YES;
        ACCBLOCK_INVOKE(self.cameraPureModeBlock, YES);
        [self logPureModeChange:YES];
    }
}

#pragma mark - Notfication

- (void)restorePureMode:(NSNotification *)noti
{
    if (self.pureMode && noti.object == self.recordController) {
        self.pureMode = NO;
        ACCBLOCK_INVOKE(self.cameraPureModeBlock, NO);
        [self logPureModeChange:NO];
    }
}

@end
