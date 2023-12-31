//
//  ACCRequestModel.m
//  Pods
//
//  Created by chengfei xiao on 2019/8/20.
//

#import "ACCRequestModel.h"

@implementation ACCRequestModel

@synthesize bodyBlock = _bodyBlock;
@synthesize fileName = _fileName;
@synthesize fileURL = _fileURL;
@synthesize headerField = _headerField;
@synthesize needCommonParams = _needCommonParams;
@synthesize objectClass = _objectClass;
@synthesize params = _params;
@synthesize targetPath = _targetPath;
@synthesize timeout = _timeout;
@synthesize urlString = _urlString;
@synthesize requestType = _requestType;



- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestType = ACCRequestTypeGET;
        self.needCommonParams = YES;
    }
    return self;
}

@end
