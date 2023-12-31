//
//	AWECloudCommandMultiData.m
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/10/9. 
//

#import "AWECloudCommandMultiData.h"

@implementation AWECloudCommandMultiData

- (NSString *)fileName {
    return _fileName ?: @"";
}

- (NSString *)fileType {
    return _fileType ?: @"";
}

- (NSString *)mimeType {
    return _mimeType ?: @"";
}

@end
