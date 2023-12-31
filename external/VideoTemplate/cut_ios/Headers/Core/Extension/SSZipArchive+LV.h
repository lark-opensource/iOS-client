//
//  SSZipArchive+LV.h
//  LVTemplate
//
//  Created by iRo on 2019/9/16.
//

#import <SSZipArchive/SSZipArchive.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSZipArchive (LV)
- (BOOL)lv_createZipFileWithContentsOfDirectory:(NSString *)directoryPath
                                       password:(nullable NSString *)password
                                progressHandler:(void(^ _Nullable)(NSUInteger entryNumber, NSUInteger total))progressHandler;

- (void)lv_cancelCreateZip;
@end

NS_ASSUME_NONNULL_END
