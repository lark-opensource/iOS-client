//
//  BDDYCZipArchiveProtocol.h
//  BDDynamically
//
//  Created by zuopengliu on 7/3/2018.
//

#import <Foundation/Foundation.h>


#if __has_include(<SSZipArchive/SSZipArchive.h>)
#include <SSZipArchive/SSZipArchive.h>
#define ENABLE_SSZIPARCHIVE_LIB 1
#endif



//
//#if ENABLE_SSZIPARCHIVE_LIB == 1
//
//extern struct unz_file_info_s;
//
//#endif
//

NS_ASSUME_NONNULL_BEGIN


@protocol BDDYCZipArchive <NSObject>
@required
/**
 * open an existing zip file ready for expanding.
 *
 * @param zipFile     the path to a zip file to be opened.
 * @return BOOL YES on success
 */
- (BOOL)UnzipOpenFile:(NSString *)zipFile;

/**
 * Expand all files in the zip archive into the specified directory.
 *
 * If a delegate has been set and responds to OverWriteOperation: it can
 * return YES to overwrite a file, or NO to skip that file.
 *
 * On completion, the property `unzippedFiles` will be an array populated
 * with the full paths of each file that was successfully expanded.
 *
 * @param path    the directory where expanded files will be created
 * @param overwrite    should existing files be overwritten
 * @return BOOL YES on success
 */
- (BOOL)UnzipFileTo:(NSString *)path overWrite:(BOOL)overwrite;

/**
 an array of files that were successfully expanded. Available after calling UnzipFileTo:overWrite:
 */
@property (nonatomic, readonly, strong) NSArray *unzippedFiles;

@optional

- (BOOL)UnzipOpenFile:(NSString *)zipFile Password:(NSString *)password;

#if ENABLE_SSZIPARCHIVE_LIB == 1
/**
 SSZipArchive API
 */
+ (BOOL)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
        progressHandler:(void (^_Nullable)(NSString *entry, struct unz_file_info_s zipInfo, long entryNumber, long total))progressHandler
      completionHandler:(void (^_Nullable)(NSString *path, BOOL succeeded, NSError * _Nullable error))completionHandler;

#endif

@end


NS_ASSUME_NONNULL_END
