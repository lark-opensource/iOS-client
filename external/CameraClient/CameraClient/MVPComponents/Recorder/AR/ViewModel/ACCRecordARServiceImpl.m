//
//  ACCRecordARServiceImpl.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/4/7.
//

#import "ACCRecordARServiceImpl.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCRecordARServiceImpl()
@property (nonatomic, strong, readwrite) RACSignal *showARInputSignal;
@property (nonatomic, strong, readwrite) RACSubject *showARInputSubject;

@property (nonatomic, strong, readwrite) RACSignal *dismissARInputSignal;
@property (nonatomic, strong, readwrite) RACSubject *dismissARInputSubject;

@property (nonatomic, strong, readwrite) RACSignal *inputTextChangeSignal;
@property (nonatomic, strong, readwrite) RACSubject *inputTextChangeSubject;

@property (nonatomic, strong, readwrite) RACSignal *inputCompleteSignal;
@property (nonatomic, strong, readwrite) RACSubject *inputCompleteSubject;

@end


@implementation ACCRecordARServiceImpl
@synthesize arGesturesDelegate = _arGesturesDelegate;

#pragma mark - Life Cycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    [_showARInputSubject sendCompleted];
    [_dismissARInputSubject sendCompleted];
    [_inputTextChangeSubject sendCompleted];
    [_inputCompleteSubject sendCompleted];
}

#pragma mark - gettter

- (RACSignal *)showARInputSignal
{
    return self.showARInputSubject;
}

- (RACSubject *)showARInputSubject
{
    if (!_showARInputSubject) {
        _showARInputSubject = [RACSubject subject];
    }
    return _showARInputSubject;
}

- (RACSignal *)dismissARInputSignal
{
    return self.dismissARInputSubject;
}

- (RACSubject *)dismissARInputSubject
{
    if (!_dismissARInputSubject) {
        _dismissARInputSubject = [RACSubject subject];
    }
    return _dismissARInputSubject;
}

- (RACSignal<ACCInputTextChangetPack> *)inputTextChangeSignal
{
    return self.inputTextChangeSubject;
}

- (RACSubject *)inputTextChangeSubject
{
    if (!_inputTextChangeSubject) {
        _inputTextChangeSubject = [RACSubject subject];
    }
    return _inputTextChangeSubject;
}

- (RACSignal *)inputCompleteSignal
{
    return self.inputCompleteSubject;
}

- (RACSubject *)inputCompleteSubject
{
    if (!_inputCompleteSubject) {
        _inputCompleteSubject = [RACSubject subject];
    }
    return _inputCompleteSubject;
}

- (AWEVideoRecorderARGestureDelegateModel *)arGesturesDelegate
{
    if (!_arGesturesDelegate) {
        _arGesturesDelegate = [[AWEVideoRecorderARGestureDelegateModel alloc] init];
    }
    return _arGesturesDelegate;
}

#pragma mark - public methods

- (void)sendSignalARInputShowWithMsg:(IESMMEffectMessage *)msg
{
    [self.showARInputSubject sendNext:msg];
}

- (void)sendSignalARInputDismiss
{
    [self.dismissARInputSubject sendNext:nil];
}

- (void)sendSignalWhenInputTextChanged:(NSString *)text message:(IESMMEffectMessage *)messageModel
{
    [self.inputTextChangeSubject sendNext:RACTuplePack(text, messageModel)];
}

- (void)sendSignalWhenInputComplete:(BOOL)confirmTextInput
{
    [self.inputCompleteSubject sendNext:@(confirmTextInput)];
}

@end
