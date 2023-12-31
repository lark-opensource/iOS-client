//
//  BDPLocalFileConst.m
//  Timor
//
//  Created by houjihu on 2020/5/21.
//

#import <Foundation/Foundation.h>
#import "BDPLocalFileConst.h"

NSString *const BDPLocalPackageFileName = @"app.ttpkg";
long long const BDP_MAX_MICRO_APP_FILE_SIZE = 200 * 1024 * 1024;

NSString *const APP_PRIVATE_TEMP_FOLDER_NAME = @"private_tmp";

NSString * APP_FILE_TEMP_PREFIX(void) {
    return [NSString stringWithFormat:@"%@://%@/", BDP_TTFILE_SCHEME, APP_TEMP_DIR_NAME];
}

NSString * APP_FILE_USER_PREFIX(void) {
    return [NSString stringWithFormat:@"%@://%@/", BDP_TTFILE_SCHEME, APP_USER_DIR_NAME];
}

NSString *const APP_PKG_DIR = @"/";
