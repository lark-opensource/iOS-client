//
//  ACCCaptureComponentScanPlugin.m
//  Indexer
//
//  Created by xiafeiyu on 11/9/21.
//

#import "ACCCaptureComponentScanPlugin.h"
#import "ACCCaptureComponent.h"

#import "ACCScanService.h"

@interface ACCCaptureComponentScanPlugin () <ACCScanServiceSubscriber>

@property (nonatomic, strong, readonly) ACCCaptureComponent *hostComponent;

@property (nonatomic, weak) id<ACCScanService> scanService;
@property (nonatomic, strong, nullable) BOOL(^willAppearPredicate)(id _Nullable input, id *_Nullable output);

@end

@implementation ACCCaptureComponentScanPlugin

@synthesize component;

+ (id)hostIdentifier
{
    return [ACCCaptureComponent class];
}

- (void)bindServices:(nonnull id<IESServiceProvider>)serviceProvider
{
    self.scanService = IESAutoInline(serviceProvider, ACCScanService);
    [self.scanService addSubscriber:self];
}

#pragma mark - ACCScanServiceSubscriber

- (void)scanService:(id<ACCScanService>)scanService didSwitchModeFrom:(ACCScanMode)oldMode to:(ACCScanMode)mode
{
    if (mode == ACCScanModeQRCode) {
        self.willAppearPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
            return NO;
        };
        [self.hostComponent.startVideoCaptureOnWillAppearPredicate addPredicate:self.willAppearPredicate with:self];
    } else {
        [self.hostComponent.startVideoCaptureOnWillAppearPredicate removePredicate:self.willAppearPredicate];
        self.willAppearPredicate = nil;
    }
}

- (ACCCaptureComponent *)hostComponent
{
    return self.component;
}

@end
