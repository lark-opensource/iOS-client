//
//  IESMetadataMappedFile.m
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import "IESMetadataMappedFile.h"

#import "IESMetadataUtils.h"
#import "IESMetadataLog.h"

#include <sys/mman.h>

static int IESMetadataMmapSize = 16 * 1024;

@interface IESMetadataMappedFile ()

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, assign) int mapLength;

@end

@implementation IESMetadataMappedFile
{
    int _fd;
    char *_mappedPointer;
    int _currentFileSize;
    int _currentMappedLength;
}

- (void)dealloc
{
    [self resetFile];
}

+ (instancetype)mappedFileWithPath:(NSString *)filePath mapLength:(int)mapLength
{
    IESMetadataMappedFile *mappedFile = [[self alloc] init];
    mappedFile.filePath = filePath;
    mappedFile.mapLength = mapLength;
    
    [mappedFile mapFile];
    IESMetadataCheckFileProtection(filePath);
    
    return mappedFile;
}

- (BOOL)extendFile
{
    int fileSize = _currentFileSize + 16 * 1024;
    if (![self extendFileToSize:fileSize]) {
        return NO;
    }
    if (_currentMappedLength < fileSize) {
        if (![self mmapWithLength:fileSize]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)resetToNewFile
{
    int fileSize = IESMetadataMmapSize;
    if (![self safeTruncateFileToSize:fileSize]) {
        return NO;
    }
    if (!IESMetadataFillFileWithZero(_fd, 0, fileSize)) {
        IESMetadataLogError("fail to write zero to file [%@] with size(%d), %s",
                            _filePath, fileSize, strerror(errno));
        return NO;
    }
    _currentFileSize = fileSize;
    IESMetadataLogInfo("reset file [%@] to size(%d)", _filePath, fileSize);
    
    return [self mmapWithLength:MAX(_mapLength, _currentFileSize)];
}

#pragma mark - Private

- (void)mapFile
{
    _fd = open(_filePath.UTF8String, O_RDWR | O_CREAT | O_CLOEXEC, S_IRWXU);
    if (_fd < 0) {
        IESMetadataLogError("fail to open %@, %s", _filePath, strerror(errno));
        return;
    }

    _currentFileSize = IESMetadataGetFileSize(_fd);
    
    // round up to (n * pagesize)
    if (_currentFileSize < IESMetadataMmapSize || (_currentFileSize % IESMetadataMmapSize != 0)) {
        int roundSize = ((_currentFileSize / IESMetadataMmapSize) + 1) * IESMetadataMmapSize;
        if (![self extendFileToSize:roundSize]) {
            return;
        }
    }
    
    [self mmapWithLength:MAX(_mapLength, _currentFileSize)];
    
    IESMetadataLogInfo("map file at %@, fileSize : %d, mappedLength : %d", _filePath, _currentFileSize, _currentMappedLength);
}

- (BOOL)extendFileToSize:(int)fileSize
{
    if (![self safeTruncateFileToSize:fileSize]) {
        return NO;
    }
    if (!IESMetadataFillFileWithZero(_fd, _currentFileSize, fileSize - _currentFileSize)) {
        IESMetadataLogError("fail to write zero to file [%@] from size(%d) to size(%d), %s",
                            _filePath, _currentFileSize, fileSize, strerror(errno));
        return NO;
    }
    _currentFileSize = fileSize;
    IESMetadataLogInfo("extent file [%@] to size %d", _filePath, fileSize);
    return YES;
}

- (BOOL)safeTruncateFileToSize:(int)fileSize
{
    if (_fd < 0) {
        return NO;
    }
    if (_currentFileSize == fileSize) {
        return NO;
    }
    if (ftruncate(_fd, fileSize) != 0) {
        IESMetadataLogError("fail to truncate file [%@] from size(%d) to size(%d), %s",
                            _filePath, _currentFileSize, fileSize, strerror(errno));
        return NO;
    }
    return YES;
}

- (BOOL)mmapWithLength:(int)mmapLength
{
    if (_currentMappedLength == mmapLength) {
        return YES;
    }
    if (_mappedPointer) {
        if (munmap(_mappedPointer, _currentMappedLength) != 0) {
            IESMetadataLogError("fail to munmap [%@], %s", _filePath, strerror(errno));
        }
    }
    
    _mappedPointer = (char *)mmap(_mappedPointer, mmapLength, PROT_READ | PROT_WRITE, MAP_SHARED, _fd, 0);
    if (_mappedPointer == MAP_FAILED) {
        IESMetadataLogError("fail to mmap [%@], %s", _filePath, strerror(errno));
        [self resetFile];
        return NO;
    }
    
    IESMetadataLogInfo("mmap [%@] to size %d successfully", _filePath, mmapLength);
    _currentMappedLength = mmapLength;
    return YES;
}

- (void)resetFile
{
    if (_mappedPointer && _mappedPointer != MAP_FAILED) {
        if (munmap(_mappedPointer, _currentMappedLength) != 0) {
            IESMetadataLogError("fail to munmap [%@], %s", _filePath, strerror(errno));
        }
    }
    _mappedPointer = NULL;
    _currentMappedLength = 0;

    if (_fd >= 0) {
        if (close(_fd) != 0) {
            IESMetadataLogError("fail to close [%@], %s", _filePath, strerror(errno));
        }
    }
    _fd = -1;
    _currentFileSize = 0;
}

- (BOOL)validateAction:(const char *)action location:(int)location length:(int)length
{
    if (!_mappedPointer || _mappedPointer == MAP_FAILED) {
        IESMetadataLogWarning("[%@] is not mapped(fd : %d mappedLength : %d)", _filePath, _fd, _currentMappedLength);
        return NO;
    }
    if (location + length <= _currentFileSize) {
        return YES;
    }
    IESMetadataLogWarning("%s with length (%d) at location(%d) out of file(size : %d)",
                        action, length, location, _currentFileSize);
    return NO;
}

#pragma mark - Read

- (NSData *)dataAtLocation:(int)location length:(int)length
{
    if ([self validateAction:"read data" location:location length:length]) {
        return [NSData dataWithBytes:(_mappedPointer + location) length:length];
    }
    return nil;
}

- (bool)boolValueAtLocation:(int)location
{
    bool value = false;
    int length = sizeof(bool);
    if ([self validateAction:"read bool" location:location length:length]) {
        memcpy(&value, _mappedPointer + location, length);
    }
    return value;
}

- (int)intValueAtLocation:(int)location
{
    int value = 0;
    int length = sizeof(int);
    if ([self validateAction:"read int" location:location length:length]) {
        memcpy(&value, _mappedPointer + location, length);
    }
    return value;
}

- (const char *)charsAtLocation:(int)location length:(int)length
{
    if ([self validateAction:"read chars" location:location length:length]) {
        return [[NSString alloc] initWithBytes:(_mappedPointer + location)
                                        length:length
                                      encoding:NSUTF8StringEncoding].UTF8String;
    }
    return "";
}

- (uint32_t)crc32AtLocation:(int)location
{
    uint32_t crc32 = 0;
    int length = sizeof(uint32_t);
    if ([self validateAction:"read crc32" location:location length:length]) {
        memcpy(&crc32, _mappedPointer + location, length);
    }
    return crc32;
}

#pragma mark - Write

- (void)writeData:(NSData *)data location:(int)location
{
    int length = (int)data.length;
    if (length == 0) {
        return;
    }
    if ([self validateAction:"write data" location:location length:length]) {
        memcpy(_mappedPointer + location, data.bytes, length);
    }
}

- (void)writeBool:(bool)boolValue location:(int)location
{
    int length = sizeof(bool);
    if ([self validateAction:"write bool" location:location length:length]) {
        memcpy(_mappedPointer + location, &boolValue, length);
    }
}

- (void)writeIntValue:(int)intValue location:(int)location
{
    int length = sizeof(int);
    if ([self validateAction:"write int" location:location length:length]) {
        memcpy(_mappedPointer + location, &intValue, length);
    }
}

- (void)writeChars:(const char *)chars location:(int)location
{
    int length = (int)strlen(chars);
    if ([self validateAction:"write chars" location:location length:length]) {
        memcpy(_mappedPointer + location, chars, length);
    }
}

- (void)writeCrc32:(uint32_t)crc32 location:(int)location
{
    int length = sizeof(uint32_t);
    if ([self validateAction:"write crc32" location:location length:length]) {
        memcpy(_mappedPointer + location, &crc32, length);
    }
}

#pragma mark - Accessor

- (int)fileSize
{
    return _currentFileSize;
}

@end
