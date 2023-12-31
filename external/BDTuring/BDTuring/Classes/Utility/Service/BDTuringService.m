//
//  BDTuringService.m
//  BDTuring
//
//  Created by bob on 2019/9/18.
//

#import "BDTuringService.h"
#import "BDTuringServiceCenter.h"

@interface BDTuringService ()

@property (nonatomic, copy) NSString *appID;

@end

@implementation BDTuringService

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super init];
    if (self) {
        self.appID = appID;
    }

    return self;
}

- (NSString *)serviceName {
    return @"";
}

- (void)registerService {
    [[BDTuringServiceCenter defaultCenter] registerService:self];
}

- (void)unregisterService {
    [[BDTuringServiceCenter defaultCenter] unregisterService:self];
}

- (BOOL)serviceAvailable {
    return YES;
}

@end
