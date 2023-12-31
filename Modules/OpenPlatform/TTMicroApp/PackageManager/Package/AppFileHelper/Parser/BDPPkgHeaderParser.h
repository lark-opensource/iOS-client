//
//  BDPPkgHeaderParser.h
//  Timor
//
//  Created by 傅翔 on 2019/1/22.
//

#import <Foundation/Foundation.h>
@class BDPPkgHeaderInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 流式包 文件描述信息解析器
 */
@interface BDPPkgHeaderParser : NSObject
-(instancetype)initWithProtection:(BOOL) enable;
/** 版本解析出来的回调 */
@property (nonatomic, nullable, copy) BOOL (^versionValidateBlk)(uint32_t version);
/** 文件头全部解析完的回调 */
@property (nonatomic, nullable, copy) void (^completionBlk)(BDPPkgHeaderInfo *_Nullable fileInfo, NSError *_Nullable error);
@property (nonatomic, readonly, copy) NSData *availableData;
@property (nonatomic, readonly, assign) int64_t size;

@property (nonatomic, readonly, strong) NSDate *beginDate;

- (void)appendData:(NSData *)data;
- (void)emptyData;

@end

NS_ASSUME_NONNULL_END
