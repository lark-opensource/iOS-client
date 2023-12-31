//
//  ACCRecordCloseViewModel.m
//  Pods
//
//  Created by liyingpeng on 2020/5/19.
//

#import "ACCRecordCloseViewModel.h"

@interface ACCRecordCloseViewModel ()

@property (nonatomic, strong, readwrite) RACSubject *manullyClickCloseButtonSuccessfullyCloseSubject; // click close button and successfully close record page signal
@property (nonatomic, strong, readwrite) RACSignal *manullyClickCloseButtonSuccessfullyCloseSignal; // click close button and successfully close record page signal

@end

@implementation ACCRecordCloseViewModel

- (void)dealloc
{
    [self.manullyClickCloseButtonSuccessfullyCloseSubject sendCompleted];
}

- (RACSubject *)manullyClickCloseButtonSuccessfullyCloseSubject
{
    if (!_manullyClickCloseButtonSuccessfullyCloseSubject) {
        _manullyClickCloseButtonSuccessfullyCloseSubject = [RACSubject subject];
    }
    return _manullyClickCloseButtonSuccessfullyCloseSubject;
}

- (RACSignal *)manullyClickCloseButtonSuccessfullyCloseSignal
{
    return self.manullyClickCloseButtonSuccessfullyCloseSubject;
}

- (void)manullyClickCloseButtonSuccessfullyClose {
    [self.manullyClickCloseButtonSuccessfullyCloseSubject sendNext:nil];
}

@end
