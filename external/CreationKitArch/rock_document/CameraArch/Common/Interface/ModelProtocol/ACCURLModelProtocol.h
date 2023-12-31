//
//  ACCURLModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/1/12.
//

#import <Foundation/Foundation.h>

#ifndef ACCURLModelProtocol_h
#define ACCURLModelProtocol_h

NS_ASSUME_NONNULL_BEGIN

@protocol ACCURLModelProtocol <NSObject, NSCopying>

@property (nonatomic, assign) CGFloat sizeByte;
@property (nonatomic,   copy) NSString *URI;

- (NSArray *)originURLList;
- (NSArray *)whiteKeys;
- (CGFloat)imageWidth;
- (CGFloat)imageHeight;
- (NSString *)fileCs;
- (NSString *)URLKey;

- (NSArray *)URLList;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCURLModelProtocol_h */
