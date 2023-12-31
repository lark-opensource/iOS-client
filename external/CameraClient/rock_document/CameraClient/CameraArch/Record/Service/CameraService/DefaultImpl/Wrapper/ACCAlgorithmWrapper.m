//
//  ACCAlgorithmWrapper.m
//  Pods
//
//  Created by liyingpeng on 2020/5/29.
//

#import "ACCAlgorithmWrapper.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitRTProtocol/ACCCameraDefine.h>
#import "ACCCameraFactory.h"
#import <TTVideoEditor/VERecorder.h>

@interface ACCAlgorithmWrapper () <ACCCameraBuildListener>

@property (nonatomic, weak) id<VERecorderPublicProtocol> camera;
@property (nonatomic, strong) ACCCameraSubscription *subscription;

@property (nonatomic, assign, readwrite) IESMMAlgorithm externalAlgorithm;
@property (nonatomic, assign) unsigned long long algorithmParam;

@end

@implementation ACCAlgorithmWrapper
@synthesize lastRedPacketRecognised = _lastRedPacketRecognised;
@synthesize hasDetectMale = _hasDetectMale;
@synthesize camera = _camera;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.externalAlgorithm |= (0x00001000 | 1);
        self.algorithmParam |= ((0x01 | 0x02 | 0x20) * 0x1000000000);
    }
    return self;
}

- (void)setCameraProvider:(id<ACCCameraProvider>)cameraProvider {
    [cameraProvider addCameraListener:self];
}

- (void)appendAlgorithm:(IESMMAlgorithm)algorithm
{
    self.externalAlgorithm |= algorithm;
    [self updateAlgorithmAndCallBack];
}

- (void)addBachAlgorithmName:(NSString *)graphName config:(NSString *)algorithmConfig algoType:(IESMMAlgorithmEffectBachType)algoType
{
    [self.camera addBachAlgorithmName:graphName config:algorithmConfig algoType:algoType];
}

- (void)removeAllBachAlgorithm
{
    [self.camera removeAllBachAlgorithm];
}

#pragma mark - ACCCameraBuildListener

- (void)onCameraInit:(id<VERecorderPublicProtocol>)camera {
    self.camera = camera;
}

#pragma mark - setter & getter

- (void)setCamera:(id<VERecorderPublicProtocol>)camera {
    _camera = camera;
    [self updateAlgorithmAndCallBack];
    [self enableEffectExternalAlgorithm:YES];
}

- (void)enableEffectExternalAlgorithm:(BOOL)enable
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera setAlgorithmRequirement:self.externalAlgorithm algorithmParam:self.algorithmParam enableDetect:enable];
}

- (void)forceDetectBuffer:(NSInteger)count
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera forceDetectBuffer:count];
}

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

- (void)addSubscriber:(id<ACCAlgorithmEvent>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}

#pragma mark - getter setter

- (void)setHasDetectMale:(BOOL)hasDetectMale
{
    if (_hasDetectMale != hasDetectMale) {
        _hasDetectMale = hasDetectMale;
    }
    [self.subscription performEventSelector:@selector(onDetectMaleChanged:) realPerformer:^(id<ACCAlgorithmEvent> subscriber) {
        [subscriber onDetectMaleChanged:hasDetectMale];
    }];
}

#pragma mark - Private method

- (void)updateAlgorithmAndCallBack
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    @weakify(self);
    [self.camera setAlgorithmResultRequirement:self.externalAlgorithm withCallbackBlock:^(NSArray<IESMMAlgorithmResultData *> * _Nonnull result, IESMMAlgorithm type) {
        @strongify(self);
        acc_dispatch_main_async_safe(^{
            [self.subscription performEventSelector:@selector(onExternalAlgorithmCallback:type:) realPerformer:^(id<ACCAlgorithmEvent> subscriber) {
                [subscriber onExternalAlgorithmCallback:result type:type];
            }];
        });
    }];
}

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
