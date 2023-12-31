//
//  BDImageMetaInfo.h
//  BDWebImage
//
//  Created by wby on 2021/9/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDWebImageRequest;

@interface BDImageMetaInfo : NSObject

@property (nonatomic, assign) NSUInteger fileSize;     // 下载后文件大小

@property (nonatomic, assign) NSUInteger memoryFootprint;  // 预计解码后图片内存占用

@property (nonatomic, assign) NSUInteger width;       // 图片宽度，px

@property (nonatomic, assign) NSUInteger height;      // 图片高度，px

@property (nonatomic, copy) NSString *webURL;        // 图片下载地址

@property (nonatomic, weak) UIView *requestView;      // 对应的view，可能为空

- (instancetype)initWithRequest:(BDWebImageRequest *)request data:(NSData *)data; 

@end

NS_ASSUME_NONNULL_END
