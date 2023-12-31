//
//  BDPLocalFileInfo.h
//  Timor
//
//  Created by 傅翔 on 2019/2/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPLocalFileInfo : NSObject

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *pkgName;
/** 文件是否位于pkg内 */
@property (nonatomic, assign) BOOL isInPkg;

/** file路径 */
@property (nonatomic, nullable, copy) NSString *path;
/** 包内相对路径, 可能为nil */
@property (nonatomic, nullable, copy) NSString *pkgPath;

@end

NS_ASSUME_NONNULL_END
