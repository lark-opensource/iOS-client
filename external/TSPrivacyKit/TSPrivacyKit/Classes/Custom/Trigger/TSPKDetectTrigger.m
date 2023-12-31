//
//  TSPKDetectTrigger.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import "TSPKDetectTrigger.h"
#import "TSPKEvent.h"

@implementation TSPKDetectTrigger

- (instancetype _Nullable)initWithParams:(NSDictionary *_Nonnull)params apiType:(NSString *_Nonnull)apiType
{
    if (self = [super init]) {
        self.interestAPIType = apiType;
        [self decodeParams:params];
        [self setup];
    }
    return self;
}

- (void)updateWithParams:(NSDictionary *_Nonnull)params
{
    [self decodeParams:params];
}

- (void)decodeParams:(NSDictionary *_Nonnull)params
{
    NSAssert(false, @"should be override by subclass");
}

- (void)setup
{
    NSAssert(false, @"should be override by subclass");
}

- (BOOL)canHandelEvent:(TSPKEvent *_Nonnull)event
{
    TSPKAPIModel *apiModel = event.eventData.apiModel;
    if ([apiModel.pipelineType isEqualToString:self.interestAPIType] && !apiModel.isNonsenstive) {
        return YES;
    }
    return NO;
}

@end
