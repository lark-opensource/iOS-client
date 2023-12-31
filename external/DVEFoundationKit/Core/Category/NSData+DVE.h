//
//  NSData+DVE.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (DVE)

- (BOOL)dve_isGIFImage;

- (NSString *)dve_md5String;

@end

NS_ASSUME_NONNULL_END
