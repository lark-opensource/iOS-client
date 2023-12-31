//
//  BDDownloadURLSessionManager.h
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/12/4.
//

#import "BDDownloadManager.h"

@interface BDDownloadURLSessionManager : BDDownloadManager
@property (nonatomic, strong, readonly)NSURLSession *session;
@end
