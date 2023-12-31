//
//  ACCEditPlayerViewModel.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/7/8.
//

#import "ACCEditPlayerViewModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>

@interface ACCEditPlayerViewModel()

@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;

@property (nonatomic, strong, readwrite) RACBehaviorSubject *playerShouldPlaySignal;

@end


@implementation ACCEditPlayerViewModel
@synthesize shouldPlay = _shouldPlay;

IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol);

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    [_playerShouldPlaySignal sendCompleted];
}

#pragma mark - getter

- (RACBehaviorSubject *)playerShouldPlaySignal {
    if (!_playerShouldPlaySignal) {
        _playerShouldPlaySignal = [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(YES)];
    }
    return _playerShouldPlaySignal;
}

#pragma mark - ACCEditPlayerProvideProtocol

- (void)setShouldPlay:(NSNumber *)shouldPlay {
    _shouldPlay = shouldPlay;
}

@end
