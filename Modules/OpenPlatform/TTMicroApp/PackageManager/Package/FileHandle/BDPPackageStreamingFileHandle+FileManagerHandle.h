//
//  BDPPackageStreamingFileHandle+FileManagerHandle.h
//  Timor
//
//  Created by houjihu on 2020/7/17.
//

#import "BDPPackageStreamingFileHandle.h"
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPPackageStreamingFileHandle (FileManagerHandle) <BDPPkgCommonAsyncReadDataHandleProtocol>

@end

NS_ASSUME_NONNULL_END
