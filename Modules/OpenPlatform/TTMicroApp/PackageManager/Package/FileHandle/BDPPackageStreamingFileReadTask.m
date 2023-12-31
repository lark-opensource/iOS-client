//
//  BDPPackageStreamingFileReadTask.m
//  Timor
//
//  Created by houjihu on 2020/7/16.
//

#import "BDPPackageStreamingFileReadTask.h"

@implementation BDPPackageStreamingFileReadTask

#if DEBUG
- (NSString *)description
{
    return [NSString stringWithFormat:@"BDPPackageStreamingFileReadTask: filePath: %@, indexInfo: %@", self.filePath, self.indexInfo.debugDescription];
}
#endif
@end
