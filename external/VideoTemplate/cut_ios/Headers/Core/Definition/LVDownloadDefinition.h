//
//  LVDownloadDefinition.h
//  Pods
//
//  Created by Chipengliu on 2020/5/27.
//

FOUNDATION_EXTERN NSString * const LVResourceDownloadErrorDomain;

/**
 资源下载错误类型

 - LVResourceDownloadErrorTypeCanceled: 下载任务取消
 - LVResourceDownloadErrorTypeDownloadEffectListFailed: 下载effect列表失败
 - LVResourceDownloadErrorTypeDownloadEffectListEmpty: 下载effect列表空
 - LVResourceDownloadErrorTypeDownloadEffectFailed: 下载具体的effect失败
 - LVResourceDownloadErrorTypeDownloadFontFailed: 下载字体文件失败
 - LVResourceDownloadErrorTypeUnzipFileFailed: 解压缩文件失败
 - LVResourceDownloadErrorTypeMoveFileFailed: 移动下载文件失败
 - LVResourceDownloadErrorTypeCopyFileFailed: 拷贝下载文件失败
 - LVResourceDownloadErrorTypeResourceMd5Empty: 资源的md5不存在
 - LVResourceDownloadErrorTypeResourceMd5Error: 资源文件的MD5值错误
 */
typedef NS_ENUM(NSUInteger, LVResourceDownloadErrorType) {
    LVResourceDownloadErrorTypeUnknown = 0,
    LVResourceDownloadErrorTypeCanceled = 10000,
    LVResourceDownloadErrorTypeDownloadEffectListFailed = 10001,
    LVResourceDownloadErrorTypeDownloadEffectListEmpty = 10002,
    LVResourceDownloadErrorTypeDownloadEffectFailed = 10003,
    LVResourceDownloadErrorTypeDownloadFontFailed = 1004,
    LVResourceDownloadErrorTypeUnzipFileFailed = 1005,
    LVResourceDownloadErrorTypeMoveFileFailed = 1006,
    LVResourceDownloadErrorTypeCopyFileFailed = 1007,
    LVResourceDownloadErrorTypeResourceMd5Empty = 1008,
    LVResourceDownloadErrorTypeResourceMd5Error = 1009,
};
