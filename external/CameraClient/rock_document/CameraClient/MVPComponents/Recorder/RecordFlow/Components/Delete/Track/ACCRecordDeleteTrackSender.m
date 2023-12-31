//
//  ACCRecordDeleteTrackSender.m
//  CameraClient
//
//  Created by haoyipeng on 2022/2/17.
//

#import "ACCRecordDeleteTrackSender.h"
#import <CreationKitInfra/ACCRACWrapper.h>

@interface ACCRecordDeleteTrackSender()

@property (nonatomic, strong) RACSubject *deleteButtonDidClickedSubject;
@property (nonatomic, strong) RACSubject *deleteConfirmAlertShowSubject;
@property (nonatomic, strong) RACSubject<NSNumber *> *deleteConfirmAlertActionSubject;

@end

@implementation ACCRecordDeleteTrackSender

- (void)sendDeleteButtonClickedSignal
{
    [self.deleteButtonDidClickedSubject sendNext:nil];
}

- (void)sendDeleteConfirmAlertShowSignal
{
    [self.deleteConfirmAlertShowSubject sendNext:nil];
}

- (void)sendDeleteConfirmAlertActionSignal:(ACCRecordDeleteActionType)actionType
{
    [self.deleteConfirmAlertActionSubject sendNext:@(actionType)];
}

- (void)dealloc
{
    [self.deleteButtonDidClickedSubject sendCompleted];
    [self.deleteConfirmAlertShowSubject sendCompleted];
    [self.deleteConfirmAlertActionSubject sendCompleted];
}

- (RACSignal *)deleteButtonDidClickedSignal
{
    return self.deleteButtonDidClickedSubject;
}

- (RACSignal *)deleteConfirmAlertShowSignal
{
    return self.deleteConfirmAlertShowSubject;
}

- (RACSignal<NSNumber *> *)deleteConfirmAlertActionSignal
{
    return self.deleteConfirmAlertActionSubject;
}

- (RACSubject *)deleteButtonDidClickedSubject
{
    if (!_deleteButtonDidClickedSubject) {
        _deleteButtonDidClickedSubject = [[RACSubject alloc] init];
    }
    return _deleteButtonDidClickedSubject;
}

- (RACSubject *)deleteConfirmAlertShowSubject
{
    if (!_deleteConfirmAlertShowSubject) {
        _deleteConfirmAlertShowSubject = [[RACSubject alloc] init];
    }
    return _deleteConfirmAlertShowSubject;
}

- (RACSubject *)deleteConfirmAlertActionSubject
{
    if (!_deleteConfirmAlertActionSubject) {
        _deleteConfirmAlertActionSubject = [[RACSubject alloc] init];
    }
    return _deleteConfirmAlertActionSubject;
}

@end
