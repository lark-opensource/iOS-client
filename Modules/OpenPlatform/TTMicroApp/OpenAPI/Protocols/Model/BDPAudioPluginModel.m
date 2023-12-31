//
//  BDPAudioPluginModel.m
//  Timor
//
//  Created by MacPu on 2019/5/27.
//

#import "BDPAudioPluginModel.h"

@implementation BDPAudioPluginModel

+(JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{@"encryptToken" : @"encrypt_token"}];
}

@end
