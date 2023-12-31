//
//  HMDFolderInfoModel.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/12/7.
//

#import "HMDFolderInfoModel.h"

@implementation HMDFolderInfoModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _childs = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = path;
        _childs = [NSMutableDictionary dictionary];
    }
    return self;
}

@end


@implementation HMDFolderSearchDepthInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        _subFolders = [NSMutableDictionary dictionary];
    }
    return self;
}

@end
