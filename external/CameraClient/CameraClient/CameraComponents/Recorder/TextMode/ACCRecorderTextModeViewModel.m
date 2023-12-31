//
//  ACCRecorderTextModeViewModel.m
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/11/4.
//

#import "ACCRecorderTextModeViewModel.h"

@interface ACCRecorderTextModeViewModel()

@property (nonatomic, strong) RACSubject *textModeVCDidAppearSubject;

@end

@implementation ACCRecorderTextModeViewModel

#pragma mark - audio Service

- (void)onCleared{
    [_textModeVCDidAppearSubject sendCompleted];
}

- (void)send_textModeVCDidAppearSignal{
    [self.textModeVCDidAppearSubject sendNext:nil];
}

- (RACSignal *)textModeVCDidAppearSignal{
    return self.textModeVCDidAppearSubject;
}

- (RACSubject *)textModeVCDidAppearSubject{
    if (!_textModeVCDidAppearSubject) {
        _textModeVCDidAppearSubject = [[RACSubject alloc] init];
    }
    return _textModeVCDidAppearSubject;
}

@end
