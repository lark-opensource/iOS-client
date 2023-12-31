//
//  IESMetadataUtils.h
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern int IESMetadataGetFileSize (int fd);

extern BOOL IESMetadataFillFileWithZero (int fd, int location, int length);

extern void IESMetadataCheckFileProtection (NSString *filePath);

NS_ASSUME_NONNULL_END
