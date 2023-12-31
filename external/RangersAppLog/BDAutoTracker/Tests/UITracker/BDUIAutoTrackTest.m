//
//  BDUIAutoTrackTest.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/19.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import "BDUIAutoTrackTest.h"
#import <OCMock/OCMock.h>

@implementation BDUIAutoTrackTest

- (void)setUp {
    self.track = OCMClassMock([BDAutoTrack class]);
}

- (void)tearDown {
    [self.track stopMocking];
}


@end
