//
//  MediaDecrypter.h
//  ttdecrypter
//
//  Created by guikunzhi on 2018/11/5.
//  Copyright © 2018年 gkz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^MediaDecrypterCompleionBlock)(BOOL success);

@interface MediaDecrypter : NSObject

@property (nonatomic, copy, readonly) NSString *inputPath;
@property (nonatomic, copy, readonly) NSString *outputPath;
@property (nonatomic, copy, readonly) NSString *decryptionKey;
@property (nonatomic, assign, readonly) NSInteger progress;

//use for remux, decode video
- (instancetype)initWithInputPath:(NSString *)input outputPath:(NSString *)output decryptionKey:(NSString *)decryptionKey;

//use for demux
- (instancetype)initWithInputPath:(NSString *)input;

- (void)start:(MediaDecrypterCompleionBlock)completion;

- (void)close;

- (NSDictionary *)getMetadata;

@end

NS_ASSUME_NONNULL_END
