//
//  ACCTrackerSender.m
//  CameraClient
//
//  Created by haoyipeng on 2021/3/22.
//

#import "ACCTrackerSender.h"
#import <CreationKitInfra/ACCRACWrapper.h>

@interface ACCTrackerSender ()

@property (nonatomic, strong) NSMutableArray *p_subjectArray;

@end

@implementation ACCTrackerSender

- (void)dealloc {
    for (RACSubject *subject in _p_subjectArray) {
        [subject sendCompleted];
    }
}

- (RACSubject *)createSubject
{
    RACSubject *subject = [RACSubject subject];
    [self.p_subjectArray addObject:subject];
    return subject;
}

- (NSMutableArray *)p_subjectArray {
    if (!_p_subjectArray) {
        _p_subjectArray = [NSMutableArray array];
    }
    return _p_subjectArray;
}

@end
