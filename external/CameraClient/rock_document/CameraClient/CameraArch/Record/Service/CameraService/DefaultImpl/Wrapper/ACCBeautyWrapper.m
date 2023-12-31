//
//  ACCBeautyWrapper.m
//  Pods
//
//  Created by liyingpeng on 2020/5/28.
//

#import "ACCBeautyWrapper.h"
#import <CreationKitRTProtocol/ACCCameraDefine.h>
#import "ACCCameraFactory.h"
#import <objc/message.h>
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/VERecorder.h>

@interface ACCBeautyWrapper () <ACCCameraBuildListener>

@property (nonatomic, weak) id<VERecorderPublicProtocol> camera;
@property (nonatomic, strong) NSMutableDictionary *acc_contextInfo;

@end

@implementation ACCBeautyWrapper
@synthesize acc_maleDetected = _acc_maleDetected;
@synthesize forceApply = _forceApply;
@synthesize camera = _camera;

- (void)setCameraProvider:(id<ACCCameraProvider>)cameraProvider {
    [cameraProvider addCameraListener:self];
}

#pragma mark - ACCCameraBuildListener

- (void)onCameraInit:(id<VERecorderPublicProtocol>)camera {
    self.camera = camera;
}

#pragma mark - setter & getter
- (void)setCamera:(id<VERecorderPublicProtocol>)camera {
    _camera = camera;
}

#pragma mark - ACCBeautyWrapper

- (NSMutableDictionary *)acc_contextInfo
{
    if (!_acc_contextInfo) {
        _acc_contextInfo = @{}.mutableCopy;
    }
    return _acc_contextInfo;
}

#pragma mark - interface wrapper

- (BOOL)replaceComposerNodesWithNewTag:(NSArray *)newNodes old:(NSArray<VEComposerInfo *> *)oldNodes
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera replaceComposerNodesWithNewTag:newNodes old:oldNodes];
}

- (void)appendComposerNodesWithTags:(NSArray *)nodes
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera appendComposerNodesWithTags:nodes];
}

- (void)removeComposerNodesWithTags:(NSArray *)nodes
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera removeComposerNodesWithTags:nodes];
}

- (BOOL)updateComposerNode:(NSString *)node key:(NSString *)key value:(CGFloat)value
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera updateComposerNode:node key:key value:value];
}

- (void)detectFace:(void (^)(BOOL))resultBlock
{
    if (![self p_verifyCameraContext]) {
        ACCBLOCK_INVOKE(resultBlock, NO);
        return;
    }
    [self.camera getFaceResult:^(BOOL flag) {
        ACCBLOCK_INVOKE(resultBlock, flag);
    }];
}

- (void)turnLensSharpen:(BOOL)isOn
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera turnLensSharpen:isOn];
}

#pragma mark - Private Method

- (BOOL)p_verifyCameraContext
{
    if (![self.camera cameraContext]) {
        return YES;
    }
    BOOL result = [self.camera cameraContext] == ACCCameraVideoRecordContext;
    if (!result) {
        ACC_LogError(@"Camera operation error, context not equal to ACCCameraVideoRecordContext point");
    }
    return result;
}

@end
