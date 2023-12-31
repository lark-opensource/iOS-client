//
//  TMAAddressManager.m
//  TTMicroApp-Example
//
//  Created by linxiaoyuan on 2018/6/25.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import "TMAAddressManager.h"
#import <OPFoundation/OPBundle.h>
#import <OPFoundation/EMANetworkAPI.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPUserAgent.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <SSZipArchive/SSZipArchive.h>

@implementation TMAAddressManager{
    NSArray * _areaArray;       //地区 picker 数组
}

+ (instancetype)shareInstance
{
    static id _ss_addressMangager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ss_addressMangager = [[self alloc] init];
    });
    return _ss_addressMangager;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self loadAreaData];
    }
    return self;
}

-(void)loadAreaData{
    NSString *zipPath = [[OPBundle bundle] pathForResource:@"address" ofType:@"zip"];
    // lint:disable:next lark_storage_check
    NSString *dirPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *unzipPath = [dirPath stringByAppendingPathComponent:@"op_address"];
    // lint:disable:next lark_storage_check
    [[NSFileManager defaultManager] removeItemAtPath:unzipPath error:nil];

    NSError *unzipError;
    BOOL unzipSuccess = [SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath overwrite:NO password:nil error:&unzipError];
    BDPLogInfo(@"bdp_loadAreaData, unzip result=%@, error=%@", @(unzipSuccess), unzipError);
    if (!unzipSuccess || unzipError) return;

    NSString *jsonPath = [unzipPath stringByAppendingPathComponent:@"address.json"];
    // lint:disable:next lark_storage_check
    NSData *data = [NSData dataWithContentsOfFile:jsonPath];
    NSError *error = nil;
    id jsonObject = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&error];
    if(!error && [jsonObject isKindOfClass:[NSArray class]]){
        _areaArray = jsonObject;
    }
}

-(NSArray *)getAreaArray{
    return _areaArray;
}

@end
