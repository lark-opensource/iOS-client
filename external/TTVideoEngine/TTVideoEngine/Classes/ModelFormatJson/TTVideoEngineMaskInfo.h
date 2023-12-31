//
//  TTVideoEngineMaskInfo.h
//  Pods
//
//  Created by jiangyue on 2022/7/29.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineMaskInfo : NSObject<NSSecureCoding>

@property (nonatomic, nullable, copy) NSString *version;
@property (nonatomic, nullable, copy) NSString *maskUrl;
@property (nonatomic, nullable, copy) NSString *fileId;
@property (nonatomic, nullable, copy) NSString *filehash;
@property (nonatomic, assign) NSInteger bitrate;
@property (nonatomic, assign) NSInteger headLen;
@property (nonatomic, strong) NSNumber *fileSize;
@property (nonatomic, strong) NSNumber *updatedAt;

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict;

- (NSInteger)getValueInt:(NSInteger)key;

- (nullable NSString *)getValueStr:(NSInteger)key;

- (NSDictionary *)toMediaInfoDict;

@end

NS_ASSUME_NONNULL_END
