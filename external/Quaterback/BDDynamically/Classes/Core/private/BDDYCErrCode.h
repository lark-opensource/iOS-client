//
//  BDDYCErrCode.h
//  BDDynamically
//
//  Created by zuopengliu on 7/6/2018.
//

#ifndef BDDYCErrCode_h
#define BDDYCErrCode_h



FOUNDATION_EXPORT NSString * const BDDYCErrorDomain;

typedef NS_ENUM(NSInteger, BDDYCErrCode)
{
    BDDYCErrCodeUnknown = -1,
    BDDYCSuccess,
    BDDYCErrCodeDataError,          // empty data or format error
    BDDYCErrCodeFetchListFailed,    // fetch module list fail
    BDDYCErrCodeDownloadFailed,     // download module fail
    BDDYCErrCodeWriteFileFail,      // write file fail
    BDDYCErrCodeEncryptFileFail,    // encrypt file downloaded fail
    BDDYCErrCodeUnzipConditionNotOK,// unzip condition not exist
    BDDYCErrCodeUnzipFailed,        // unzip fail
    BDDYCErrCodeVerifyFailed,       // md5 verify fail
    
    BDDYCErrCodeJSContextInitFail,
    BDDYCErrCodeJSContextRunCrash,
    
    // Brady Error Code
    BDDYCErrCodeBradyNotFoundFile,
    BDDYCErrCodeBradyInitFail,
    BDDYCErrCodeBradyParseFail,
    BDDYCErrCodeBradyLoadFail,
    BDDYCErrCodeBradyRunCrash,
    BDDYCErrCodeBradyUnloadError,

    BDDYCErrCodeHTTPError,

    BDDYCErrCodeConnectionTimeout = -1001,  //连接超时
};



#endif /* BDDYCErrCode_h */
