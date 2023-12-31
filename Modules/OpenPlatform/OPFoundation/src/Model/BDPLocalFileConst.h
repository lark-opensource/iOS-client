//
//  BDPLocalFileConst.h
//  Timor
//
//  Created by houjihu on 2020/3/23.
//

#ifndef BDPLocalFileConst_h
#define BDPLocalFileConst_h

#define kBDPLocalFileManagerLogTag  @"FM"

#define BDP_APP_TMP_FOLDER_NAME @"tmp"
#define BDP_APP_SANDBOX_FOLDER_NAME @"sandbox"
extern NSString *const APP_PRIVATE_TEMP_FOLDER_NAME; // "private_tmp"
#define BDP_PAGE_FREAM_NAME @"page-frame.html"

#define BDP_JSLIB_FOLDER_NAME @"__dev__"
#define BDP_H5JSLIB_FOLDER_NAME @"__dev__/h5jssdk"
#define BDP_OFFLINE_FOLDER_NAME @"offline"
#define BDP_INTERNALBUNDLE_FOLDER_NAME @"internalBundle"

#define BDP_TTFILE_SCHEME @"ttfile"
#define BDP_FILE_SCHEME @"file"

#define APP_TEMP_DIR_NAME @"temp"
#define APP_USER_DIR_NAME @"user"
extern NSString * APP_FILE_TEMP_PREFIX(void); // ttfile://temp/
extern NSString * APP_FILE_USER_PREFIX(void); // ttfile://user/
extern NSString *const APP_PKG_DIR; // "/"

#define BDP_PKG_AID_PARAM @"_aid_"
#define BDP_PKG_NAME_PARAM @"_pkg_"

extern long long const BDP_MAX_MICRO_APP_FILE_SIZE;

typedef NS_ENUM(NSInteger, BDPFolderPathType) {
    /** 临时目录(本次运行有效)    TTFile://temp  =>  AbsPath : App路径/tmp/ */
    BDPFolderPathTypeTemp = 0,
    /** 用户目录(长期有效)       TTFile://user  =>  AbsPath : App路径/sandbox/ */
    BDPFolderPathTypeUser,
    /** 包内（长期有效）         文件名          =>  AbsPath : App路径/小程序版本/ */
    BDPFolderPathTypePkg
};

/// 流式包文件名
extern NSString *const BDPLocalPackageFileName;

#endif /* BDPLocalFileConst_h */
