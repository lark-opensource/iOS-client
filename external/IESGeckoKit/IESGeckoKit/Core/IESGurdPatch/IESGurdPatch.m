//
//  IESGurdPatch.m
//  IESGeckoKit
//
//  Created by xinwen tan on 2021/6/30.
//

#import "IESGurdPatch.h"
#import "IESGurdLogProxy.h"
#import "IESGeckoFileMD5Hash.h"
#import "IESGeckoBSPatch.h"
#import "NSError+IESGurdKit.h"

#define HEAD @"BYTEDIFF"
#define PATCH_TEMP @"bytepatch_patch_temp_file"
#define FILE_MANAGER [NSFileManager defaultManager]

// java的byte是有符号的
typedef signed char byte;

typedef NS_ENUM(char, BytePatchType) {
    BytePatchTypeModify = 0x01,
    BytePatchTypeDelete = 0x02,
    BytePatchTypeAdd = 0x03,
    BytePatchTypeRename = 0x04,
    BytePatchTypeRewrite = 0x05,
    BytePatchTypeSame = 0x06,
};

@interface IESGurdPatch()

@property (nonatomic, copy) NSString *mSrc;
@property (nonatomic, copy) NSString *mDest;
@property (nonatomic, copy) NSString *mPatch;
@property (nonatomic, assign) int mVersion;

@property (nonatomic, strong) NSError *mError;
@property (nonatomic, strong) NSMutableSet<NSString *> *mPathHandled;
@property (nonatomic, strong) NSString *mErrorPrefix;

@property (nonatomic, strong) NSData *mPatchData;
@property (nonatomic, assign) long mPatchIndex;

@end

@implementation IESGurdPatch

+ (BOOL)checkFileMD5InDirs:(NSString *)dir1 dir2:(NSString *)dir2
{
    NSMutableArray<NSString *> *files = [NSMutableArray array];
    return [self traversalDir1:dir1 dir2:dir2 child:dir1 handleFiles:files] &&
        [self traversalDir2:dir1 dir2:dir2 child:dir2 handleFiles:files];
}

+ (BOOL)traversalDir1:(NSString *)dir1 dir2:(NSString *)dir2 child:(NSString *)child handleFiles:(NSMutableArray *)handleFiles
{
    NSArray *files = [FILE_MANAGER contentsOfDirectoryAtPath:child error:nil];
    if (!files) {
        return YES;
    }
    for (NSString *file in files) {
        if ([file isEqualToString:@".DS_Store"]) {
            continue;
        }
        NSString *fullpath = [child stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [FILE_MANAGER fileExistsAtPath:fullpath isDirectory:&isDir];
        if (isDir) {
            if (![self traversalDir1:dir1 dir2:dir2 child:fullpath handleFiles:handleFiles]) {
                return NO;
            }
        } else {
            NSString *relativePath = [self getRelativePath:fullpath root:dir1];
            NSString *dir2File = [dir2 stringByAppendingPathComponent:relativePath];
            if (![FILE_MANAGER fileExistsAtPath:dir2File]) {
                IESGurdLogError(@"dir2File not exist: %@", dir2File);
                return NO;
            }
            NSString *file1Md5 = [IESGurdFileMD5Hash md5HashOfFileAtPath:fullpath error:nil];
            NSString *file2Md5 = [IESGurdFileMD5Hash md5HashOfFileAtPath:dir2File error:nil];
            if (![file1Md5 isEqualToString:file2Md5]) {
                IESGurdLogError(@"check md5 failed: %@", dir2File);
                return NO;
            }
            [handleFiles addObject:relativePath];
        }
    }
    return YES;
}

+ (BOOL)traversalDir2:(NSString *)dir1 dir2:(NSString *)dir2 child:(NSString *)child handleFiles:(NSMutableArray *)handleFiles
{
    NSArray *files = [FILE_MANAGER contentsOfDirectoryAtPath:child error:nil];
    if (!files) {
        return YES;
    }
    for (NSString *file in files) {
        if ([file isEqualToString:@".DS_Store"]) {
            continue;
        }
        NSString *fullpath = [child stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [FILE_MANAGER fileExistsAtPath:fullpath isDirectory:&isDir];
        if (isDir) {
            if (![self traversalDir2:dir1 dir2:dir2 child:fullpath handleFiles:handleFiles]) {
                return NO;
            }
        } else {
            NSString *relativePath = [self getRelativePath:fullpath root:dir2];
            if (![handleFiles containsObject:relativePath]) {
                IESGurdLogError(@"dir2 extra file: %@", fullpath);
                return NO;
            }
        }
    }
    return YES;
}

+ (NSString *)getRelativePath:(NSString *)fullpath root:(NSString *)root
{
    return [fullpath substringFromIndex:[root length] + 1];
}

- (void)setupError:(IESGurdSyncStatus)code msg:(NSString *)msg
{
    if (self.mErrorPrefix) {
        msg = [self.mErrorPrefix stringByAppendingString:msg];
    }
    self.mError = [NSError ies_errorWithCode:code description:msg];
}

- (BOOL)patch:(NSString *_Nonnull)src
         dest:(NSString *_Nonnull)dest
        patch:(NSString *_Nonnull)patch
        error:(NSError **)error;
{
    if (![self checkParams:src dest:dest patch:patch]) {
        *error = self.mError;
        return NO;
    }
    
    self.mSrc = src;
    self.mDest = dest;
    self.mPatch = patch;
    self.mPathHandled = [NSMutableSet set];
    
    @autoreleasepool {
        if (![self doPatch]) {
            *error = self.mError;
            [FILE_MANAGER removeItemAtPath:self.mDest error:nil];
            return NO;
        }
    }
    
    IESGurdLogInfo(@"bytepatch success!");
    return YES;
}

- (BOOL)checkParams:(NSString *_Nonnull)src
               dest:(NSString *_Nonnull)dest
              patch:(NSString *_Nonnull)patch
{
    BOOL isDir = NO;
    BOOL isExist = [FILE_MANAGER fileExistsAtPath:src isDirectory:&isDir];
    if (!isExist || !isDir) {
        NSString *msg = [NSString stringWithFormat:@"param src error: %@", src];
        [self setupError:IESGurdBytePatchParamsError msg:msg];
        return NO;
    }
    
    isExist = [FILE_MANAGER fileExistsAtPath:patch isDirectory:&isDir];
    if (!isExist || isDir) {
        NSString *msg = [NSString stringWithFormat:@"param patch error: %@", patch];
        [self setupError:IESGurdBytePatchParamsError msg:msg];
        return NO;
    }
    
    isExist = [FILE_MANAGER fileExistsAtPath:dest isDirectory:&isDir];
    if (isExist) {
        if (isDir) {
            if (![FILE_MANAGER removeItemAtPath:dest error:nil]) {
                NSString *msg = [NSString stringWithFormat:@"param dest error, remove failed: %@", dest];
                [self setupError:IESGurdBytePatchParamsError msg:msg];
                return NO;
            }
        } else {
            NSString *msg = [NSString stringWithFormat:@"param dest error, is file: %@", dest];
            [self setupError:IESGurdBytePatchParamsError msg:msg];
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)doPatch
{
    self.mPatchIndex = 0;
    self.mPatchData = [NSData dataWithContentsOfFile:self.mPatch];
    if (!self.mPatchData) {
        NSString *msg = [NSString stringWithFormat:@"read patch error: %@", self.mPatch];
        [self setupError:IESGurdBytePatchReadPatchError msg:msg];
        return NO;
    }
    
    long len = [HEAD length];
    byte buffer[len];
    if (![self readBytes:buffer len:len]) {
        return NO;
    }
    NSString *head = [self bytesToString:buffer len:len];
    if (![head isEqualToString:HEAD]) {
        NSString *msg = [NSString stringWithFormat:@"not bytediff file: %@", head];
        [self setupError:IESGurdBytePatchFormatError msg:msg];
        return NO;
    }
    
    byte version = [self readByte];
    if (self.mError) {
        return NO;
    }
    if (version > 1 || version < 0) {
        NSString *msg = [NSString stringWithFormat:@"unsupported version: %d", version];
        [self setupError:IESGurdBytePatchFormatError msg:msg];
        return NO;
    }
    self.mVersion = version;
    
    if (![self handlePatch]) {
        return NO;
    }
    self.mErrorPrefix = nil;
    if (![self traversalSrc:self.mSrc]) {
        return NO;
    }
    return YES;
}

- (BOOL)handlePatch
{
    while (true)
    {
        if (self.mPatchIndex >= [self.mPatchData length]) {
            return YES;
        }
        
        NSString *path = [self readUTF];
        if (!path) {
            return NO;
        }
        
        [self.mPathHandled addObject:path];
        NSString *oldFile = [self.mSrc stringByAppendingPathComponent:path];
        byte type = [self readByte];
        if (self.mError) {
            return NO;
        }
        if (type != BytePatchTypeAdd) {
            if (![FILE_MANAGER fileExistsAtPath:oldFile]) {
                NSString *msg = [NSString stringWithFormat:@"path not exists, type: %d, path: %@", type, path];
                [self setupError:IESGurdBytePatchDataError msg:msg];
                return NO;
            }
        }

        switch (type) {
            case BytePatchTypeModify: {
                self.mErrorPrefix = [NSString stringWithFormat:@"patch failed, type:modify, path:%@, detail:", path];
                if (![self handleTypeModify:path oldFile:oldFile]) {
                    return NO;
                }
                break;
            }
            case BytePatchTypeDelete: {
                // no thing to do
                break;
            }
            case BytePatchTypeAdd: {
                self.mErrorPrefix = [NSString stringWithFormat:@"patch failed, type:add, path:%@, detail:", path];
                NSString *newFile = [self.mDest stringByAppendingPathComponent:path];
                NSString *parent = [newFile stringByDeletingLastPathComponent];
                BOOL succeed = [self createDir:parent];
                if (!succeed) {
                    return NO;
                }
                
                if (![self writeContentToFile:newFile relativePath:path]) {
                    return NO;
                }
                if (self.mVersion == 0) {
                    if (![self checkMD5:newFile]) {
                        return NO;
                    }
                }
                
                break;
            }
            case BytePatchTypeRename: {
                NSString *newPath = [self readUTF];
                if (!newPath) {
                    return NO;
                }
                self.mErrorPrefix = [NSString stringWithFormat:@"patch failed, type:rename, path:%@, newPath:%@, detail:", path, newPath];
                if (![self handleTypeRename:newPath oldFile:oldFile]) {
                    return NO;
                }
                break;
            }
            case BytePatchTypeRewrite: {
                NSString *newPath = [self readUTF];
                if (!newPath) {
                    return NO;
                }
                self.mErrorPrefix = [NSString stringWithFormat:@"patch failed, type:rewrite, path:%@, newPath:%@, detail:", path, newPath];
                if (![self handleTypeModify:newPath oldFile:oldFile]) {
                    return NO;
                }
                break;
            }
            case BytePatchTypeSame: {
                self.mErrorPrefix = [NSString stringWithFormat:@"patch failed, type:same, path:%@, detail:", path];
                if (![self handleTypeRename:path oldFile:oldFile]) {
                    return NO;
                }
                break;
            }
            default: {
                self.mErrorPrefix = nil;
                NSString *msg = [NSString stringWithFormat:@"not support change type: %d, path: %@", type, path];
                [self setupError:IESGurdBytePatchDataError msg:msg];
                return NO;
            }
        }
        self.mErrorPrefix = [NSString stringWithFormat:@"patch failed, after path:%@, detail:", path];
    }
}

- (BOOL)handleTypeModify:(NSString *)path oldFile:(NSString *)oldFile
{
    NSString *newFile = [self.mDest stringByAppendingPathComponent:path];
    NSString *parent = [newFile stringByDeletingLastPathComponent];
    BOOL succeed = [self createDir:parent];
    if (!succeed) {
        return NO;
    }
    
    NSString *patchParent = [self.mPatch stringByDeletingLastPathComponent];
    NSString *patchFile = [patchParent stringByAppendingPathComponent:PATCH_TEMP];
    if (![self writeContentToFile:patchFile relativePath:PATCH_TEMP]) {
        return NO;
    }
    
    NSString *errorMessage = nil;
    if (!IESGurdBSPatch(oldFile, newFile, patchFile, &errorMessage)) {
        NSString *msg = [NSString stringWithFormat:@"bspatch failed: %@", errorMessage];
        [self setupError:IESGurdBytePatchBSPatchError msg:msg];
        return NO;
    }
    
    [FILE_MANAGER removeItemAtPath:patchFile error:nil];
    NSString *md5 = [self readMD5];
    if (!md5) {
        return NO;
    }
    NSString *realMD5 = [IESGurdFileMD5Hash md5HashOfFileAtPath:newFile error:nil];
    if (![realMD5 isEqualToString:md5]) {
        NSString *oldFileMD5 = [IESGurdFileMD5Hash md5HashOfFileAtPath:oldFile error:nil];
        if ([oldFileMD5 isEqualToString:md5]) {
            [self setupError:IESGurdBytePatchModifySameFile msg:@"old file is same"];
        } else {
            NSString *msg = [NSString stringWithFormat:@"checkMD5 failed, realMD5: %@, expectMD5: %@", realMD5, md5];
            [self setupError:IESGurdBytePatchCheckMD5Error msg:msg];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)handleTypeRename:(NSString *)path oldFile:(NSString *)oldFile
{
    NSString *newFile = [self.mDest stringByAppendingPathComponent:path];
    if (![self copy:oldFile dest:newFile]) {
        return NO;
    }
    if (self.mVersion == 0) {
        NSString *md5 = [self readMD5];
        if (!md5) {
            return NO;
        }
        NSString *realMD5 = [IESGurdFileMD5Hash md5HashOfFileAtPath:newFile error:nil];
        if (![realMD5 isEqualToString:md5]) {
            NSString *oldFileMD5 = [IESGurdFileMD5Hash md5HashOfFileAtPath:oldFile error:nil];
            if (![realMD5 isEqualToString:oldFileMD5]) {
                NSString *msg = [NSString stringWithFormat:@"copy error, oldFileMd5: %@, newFileMd5: %@, expectMD5: %@",
                                 oldFileMD5, realMD5, md5];
                [self setupError:IESGurdBytePatchCopyError msg:msg];
            } else {
                NSString *msg = [NSString stringWithFormat:@"checkMD5 failed, not modify, realMD5: %@, expectMD5: %@", realMD5, md5];
                [self setupError:IESGurdBytePatchRenameError msg:msg];
            }
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)traversalSrc:(NSString *)src
{
    NSArray *files = [FILE_MANAGER contentsOfDirectoryAtPath:src error:nil];
    if (!files) {
        return YES;
    }
    for (NSString *file in files) {
        NSString *fullpath = [src stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [FILE_MANAGER fileExistsAtPath:fullpath isDirectory:&isDir];
        if (isDir) {
            if (![self traversalSrc:fullpath]) {
                return NO;
            }
        } else {
            NSString *relativePath = [IESGurdPatch getRelativePath:fullpath root:self.mSrc];
            if (![self.mPathHandled containsObject:relativePath]) {
                NSString *newFile = [self.mDest stringByAppendingPathComponent:relativePath];
                if (![self copy:fullpath dest:newFile]) {
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (BOOL)writeContentToFile:(NSString *)src relativePath:path
{
    if ([FILE_MANAGER fileExistsAtPath:src]) {
        if (![FILE_MANAGER removeItemAtPath:src error:nil]) {
            [self setupError:IESGurdBytePatchWriteContentToFileError msg:@"remove old file error"];
        }
    }
    long length = [self readLong];
    if (self.mError) {
        return NO;
    }
    if (length <= 0) {
        NSString *msg = [NSString stringWithFormat:@"read long error: %ld", length];
        [self setupError:IESGurdBytePatchWriteContentToFileError msg:msg];
        return NO;
    }
    NSData *content = [self readData:length];
    if (!content) {
        return NO;
    }
    
    BOOL succeed = [content writeToFile:src atomically:NO];
    if (succeed) {
        return YES;
    } else {
        [self setupError:IESGurdBytePatchWriteContentToFileError msg:@"write content error"];
        return NO;
    }
}

- (BOOL)createDir:(NSString *)path
{
    NSError *error = nil;
    // 当文件夹存在时，createDirectoryAtPath也会返回true
    BOOL succeed = [FILE_MANAGER createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    if (succeed) {
        return YES;
    } else {
        NSString *msg = [NSString stringWithFormat:@"create dir failed, reason: %@", error.localizedDescription];
        [self setupError:IESGurdBytePatchFileSystemError msg:msg];
        return NO;
    }
}

- (BOOL)copy:(NSString *)src dest:(NSString *)dest
{
    NSString *parent = [dest stringByDeletingLastPathComponent];
    if (![self createDir:parent]) {
        return NO;
    }
    NSError *error = nil;
    BOOL succeed = [FILE_MANAGER copyItemAtPath:src toPath:dest error:&error];
    if (succeed) {
        return YES;
    } else {
        NSString *msg = [NSString stringWithFormat:@"copy file failed: %@, dest: %@, reason: %@", src, dest, error.localizedDescription];
        [self setupError:IESGurdBytePatchFileSystemError msg:msg];
        return NO;
    }
}

- (NSString *)bytesToString:(byte[])buffer len:(long)len
{
    return [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
}

- (NSString *)readMD5
{
    int len = 32;
    byte md5Byte[len];
    if (![self readBytes:md5Byte len:len]) {
        return nil;
    }
    NSString *md5 = [self bytesToString:md5Byte len:len];
    if (!md5) {
        [self setupError:IESGurdBytePatchReadMd5Error msg:@"read md5 failed"];
        return nil;
    }
    return md5;
}

- (BOOL)checkMD5:(NSString *)path
{
    NSString *md5 = [self readMD5];
    if (!md5) {
        return NO;
    }
    NSString *realMD5 = [IESGurdFileMD5Hash md5HashOfFileAtPath:path error:nil];
    if (![realMD5 isEqualToString:md5]) {
        NSString *msg = [NSString stringWithFormat:@"checkMD5 failed, realMD5: %@, expectMD5: %@", realMD5, md5];
        [self setupError:IESGurdBytePatchCheckMD5Error msg:msg];
        return NO;
    }
    return YES;
}

- (byte)readByte;
{
    if (self.mPatchIndex >= [self.mPatchData length]) {
        [self setupError:IESGurdBytePatchReachEnd msg:@"readByte failed, reach end!"];
        return -1;
    }
    
    byte buffer[1];
    [self.mPatchData getBytes:buffer range:NSMakeRange(self.mPatchIndex, 1)];
    self.mPatchIndex += 1;
    return buffer[0];
}

- (BOOL)readBytes:(byte[])buffer len:(long)len;
{
    if (self.mPatchIndex >= [self.mPatchData length]) {
        [self setupError:IESGurdBytePatchReachEnd msg:@"readBytes failed, reach end!"];
        return NO;
    }
    
    if ([self.mPatchData length] - self.mPatchIndex < len) {
        [self setupError:IESGurdBytePatchReadBytesError msg:@"readBytes failed, not enough to read"];
        return NO;
    }
    [self.mPatchData getBytes:buffer range:NSMakeRange(self.mPatchIndex, len)];
    self.mPatchIndex += len;
    return YES;
}

- (short)readUnsignedShort;
{
    if (self.mPatchIndex >= [self.mPatchData length]) {
        [self setupError:IESGurdBytePatchReachEnd msg:@"readUnsignedShort failed, reach end!"];
        return -1;
    }
    
    NSData *mPatchData = [self.mPatchData subdataWithRange:NSMakeRange(self.mPatchIndex, 2)];
    unsigned short num = CFSwapInt16BigToHost(*(unsigned short *)([mPatchData bytes]));
    self.mPatchIndex += 2;
    return num;
}

- (long)readLong;
{
    if (self.mPatchIndex >= [self.mPatchData length]) {
        [self setupError:IESGurdBytePatchReachEnd msg:@"readLong failed, reach end!"];
        return -1;
    }
    
    NSData *mPatchData = [self.mPatchData subdataWithRange:NSMakeRange(self.mPatchIndex, 8)];
    long num = CFSwapInt64BigToHost(*(long *)([mPatchData bytes]));
    self.mPatchIndex += 8;
    return num;
}

// java的writeUTF，前两个字节是表示写入数据的长度
- (NSString *)readUTF;
{
    if (self.mPatchIndex >= [self.mPatchData length]) {
        [self setupError:IESGurdBytePatchReachEnd msg:@"readUTF failed, reach end!"];
        return nil;
    }
    
    unsigned short len = [self readUnsignedShort];
    if (self.mError) {
        return nil;
    }
    if (len < 0) {
        NSString *msg = [NSString stringWithFormat:@"readUTF failed, len less than 0:%d", len];
        [self setupError:IESGurdBytePatchReadUTFError msg:msg];
        return nil;
    }
    if (self.mPatchIndex + len > [self.mPatchData length]) {
        NSString *msg = [NSString stringWithFormat:@"readUTF failed, len is too big! mPatchIndex:%ld, len:%d, dataLength:%ld",
                         self.mPatchIndex, len, [self.mPatchData length]];
        [self setupError:IESGurdBytePatchReadUTFError msg:msg];
        return nil;
    }
    
    byte result[len];
    if (![self readBytes:result len:len]) {
        return nil;
    }
    NSString *str = [[NSString alloc] initWithBytes:result length:len encoding:NSUTF8StringEncoding];
    if (!str) {
        [self setupError:IESGurdBytePatchReadDataError msg:@"readUTF failed, init str error"];
        return nil;
    }
    return str;
}

- (NSData *)readData:(long)len;
{
    if (self.mPatchIndex >= [self.mPatchData length]) {
        [self setupError:IESGurdBytePatchReachEnd msg:@"readData failed, reach end!"];
        return nil;
    }
    if (self.mPatchIndex + len > [self.mPatchData length]) {
        NSString *msg = [NSString stringWithFormat:@"readData failed, len is too big! mPatchIndex:%ld, len:%ld, dataLength:%ld",
                         self.mPatchIndex, len, [self.mPatchData length]];
        [self setupError:IESGurdBytePatchReadDataError msg:msg];
        return nil;
    }
    
    NSData *subData = [self.mPatchData subdataWithRange:NSMakeRange(self.mPatchIndex, len)];
    if (!subData) {
        [self setupError:IESGurdBytePatchReadDataError msg:@"readData failed, get sub mPatchData error"];
        return nil;
    }
    self.mPatchIndex += len;
    return subData;
}

@end
