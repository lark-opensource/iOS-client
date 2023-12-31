//
//  ACCRecordFrameSamplingServiceImpl.m
//  CameraClient
//
//  Created by limeng on 2020/5/11.
//

#import "ACCRecordFrameSamplingServiceImpl.h"
#import "ACCRecordFrameSamplingHandlerChain.h"

@interface ACCRecordFrameSamplingServiceImpl () <ACCRecordFrameSamplingHandlerDelegate>

@property (nonatomic, copy) NSArray<ACCRecordFrameSamplingHandlerProtocol> *handlerChain;
@property (nonatomic, strong) NSMutableArray<ACCRecordFrameSamplingCompletionObserver> *completionObservers;

@end
@implementation ACCRecordFrameSamplingServiceImpl

@synthesize timeInterval = _timeInterval;
@synthesize currentSticker = _currentSticker;
@synthesize publishModel = _publishModel;
@synthesize multiAssetsPixaloopSelectedImages = _multiAssetsPixaloopSelectedImages;

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    self = [super init];
    if (self) {
        _handlerChain = [ACCRecordFrameSamplingHandlerChain loadHandlerChain];
        _publishModel = publishModel;
        _completionObservers = (NSMutableArray<ACCRecordFrameSamplingCompletionObserver> *)[NSMutableArray array];
    }
    return self;
}

- (void)configCameraService:(id<ACCCameraService>)cameraService
{
    for (id<ACCRecordFrameSamplingHandlerProtocol> handler in self.handlerChain) {
        [handler configCameraService:cameraService samplingContext:self];
    }
}

- (void)startWithCameraService:(id<ACCCameraService>)cameraService timeInterval:(NSTimeInterval)timeInterval;
{
    for (id<ACCRecordFrameSamplingHandlerProtocol> handler in self.handlerChain) {
        if ([handler shouldHandle:self]) {
            handler.delegate = self;
            [handler startWithCameraService:cameraService timeInterval:timeInterval];
        }
    }
}

- (void)sampleFrame
{
    for (id<ACCRecordFrameSamplingHandlerProtocol> handler in self.handlerChain) {
        if (handler.isRunning) {
            [handler sampleFrame];
        }
    }
}

- (void)stop
{
    for (id<ACCRecordFrameSamplingHandlerProtocol> handler in self.handlerChain) {
        if (handler.isRunning) {
            [handler stop];
        }
    }
}

-(void)removeAllFrames
{
    for (id<ACCRecordFrameSamplingHandlerProtocol> handler in self.handlerChain) {
        [handler removeAllFrames];
    }
}

- (void)updatePublishModel:(AWEVideoPublishViewModel *)publishModel
{
    _publishModel = publishModel;
}

- (void)updateCurrentSticker:(IESEffectModel *)currentSticker
{
    _currentSticker = currentSticker;
}

- (void)addCompletionObserver:(ACCRecordFrameSamplingCompletionObserver)observer
{
    if (![self.completionObservers containsObject:observer] && observer) {
        [self.completionObservers addObject:observer];
    }
}

- (void)removeCompletionObserver:(ACCRecordFrameSamplingCompletionObserver)observer
{
    [self.completionObservers removeObject:observer];
}

- (void)removeAllCompletionObservers
{
    [self.completionObservers removeAllObjects];
}

- (void)saveBgPhotosForTakePicture
{
    for (id<ACCRecordFrameSamplingHandlerProtocol> handler in self.handlerChain) {
        [handler saveBgPhotosForTakePicture];
    }
}

#pragma mark - ACCRecordFrameSamplingHandlerDelegate
- (void)samplingCompleted:(id<ACCRecordFrameSamplingHandlerProtocol>)handler samplingFrames:(NSArray<NSString *> *)samplingFrames
{
    if (self.completionObservers.count > 0) {
        [self.completionObservers enumerateObjectsUsingBlock:^(ACCRecordFrameSamplingCompletionObserver  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj) {
                obj(self, handler, samplingFrames);
            }
        }];
    }
}

@end
