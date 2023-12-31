//
//  BDPAppFileInfoModel.m
//  Timor
//
//  Created by 傅翔 on 2019/1/22.
//

#import "BDPPkgHeaderInfo.h"

@implementation BDPPkgHeaderInfo

- (NSString *)debugDescription {
    NSMutableString *debug = [NSMutableString string];
    [debug appendFormat:@"version: %@\n", @(_version)];
    [debug appendFormat:@"totalSize(bytes): %@\n", @(_totalSize)];
    [debug appendFormat:@"文件数量: %@\n", @(_fileIndexes.count)];
    for (BDPPkgFileIndexInfo *indexModel in _fileIndexes) {
        [debug appendFormat:@"%@\n", indexModel.debugDescription];
    }
    return [debug copy];
}

#pragma mark NSCoding
- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:@(_version) forKey:NSStringFromSelector(@selector(version))];
    if (_extInfo) {
        [aCoder encodeObject:_extInfo forKey:NSStringFromSelector(@selector(extInfo))];
    }
    if (_fileIndexes.count) {
        [aCoder encodeObject:_fileIndexes forKey:NSStringFromSelector(@selector(fileIndexes))];
    }
    if (_fileIndexesDic.count) {
        [aCoder encodeObject:_fileIndexesDic forKey:NSStringFromSelector(@selector(fileIndexesDic))];
    }
    [aCoder encodeObject:@(_totalSize) forKey:NSStringFromSelector(@selector(totalSize))];
    [aCoder encodeObject:@(_customVersion) forKey:NSStringFromSelector(@selector(customVersion))];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [super init]) {
        _version = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(version))] unsignedIntValue];
        _extInfo = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(extInfo))];
        _fileIndexes = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(fileIndexes))];
        _fileIndexesDic = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(fileIndexesDic))];
        _totalSize = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(totalSize))] longLongValue];
        _customVersion = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(customVersion))] unsignedIntValue];
    }
    return self;
}

@end


#pragma mark -
@implementation BDPPkgFileIndexInfo

- (uint32_t)endOffset {
    return _offset + _size;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@(offset: %@, size: %@)",
            _filePath,
            @(_offset),
            @(_size)];
}

#pragma mark NSCoding
- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:_filePath forKey:NSStringFromSelector(@selector(filePath))];
    [aCoder encodeObject:@(_offset) forKey:NSStringFromSelector(@selector(offset))];
    [aCoder encodeObject:@(_size) forKey:NSStringFromSelector(@selector(bdp_size))];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [super init]) {
        _filePath = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(filePath))];
        _offset = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(offset))] unsignedIntValue];
        _size = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(bdp_size))] unsignedIntValue];
    }
    return self;
}

@end
