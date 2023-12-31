//
//  TSPKEvent.m
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/15.
//

#import "TSPKEvent.h"

NSString *_Nonnull const TSPKEventTagEvent = @"Event";

@implementation TSPKEvent

- (NSString *)tag {
    return TSPKEventTagEvent;
}

- (NSString *)apiType
{
    return self.eventData.apiModel.pipelineType;
}

@end
