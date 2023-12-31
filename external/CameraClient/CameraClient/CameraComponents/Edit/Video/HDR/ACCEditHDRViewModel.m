//
//  ACCEditHDRViewModel.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/7/8.
//

#import "ACCEditHDRViewModel.h"
#import <CreativeKit/ACCMacros.h>
#import "AWEHDRModelManager.h"
#import "ACCRepoTextModeModel.h"

@interface ACCEditHDRViewModel()
@property (nonatomic, strong, readwrite) RACSignal *clearHDRSignal;
@property (nonatomic, strong, readwrite) RACBehaviorSubject *clearHDRSubject;

@end


@implementation ACCEditHDRViewModel

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    [_clearHDRSubject sendCompleted];
}

#pragma mark - getter

- (RACSignal *)clearHDRSignal
{
    return self.clearHDRSubject;
}

- (RACBehaviorSubject *)clearHDRSubject
{
    if (!_clearHDRSubject) {
        _clearHDRSubject = [RACBehaviorSubject subject];
    }
    return _clearHDRSubject;
}

#pragma mark - ACCEditHDRProvideProtocol

- (BOOL)enableVideoHDR
{
     return [AWEHDRModelManager enableVideoHDR] && !self.inputData.publishModel.repoTextMode.isTextMode;
}

- (void)clearHDR
{
    [self.clearHDRSubject sendNext:@(YES)];
}

@end
