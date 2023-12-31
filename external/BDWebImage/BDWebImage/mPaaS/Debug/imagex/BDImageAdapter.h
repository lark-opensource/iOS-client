//
//  BDImageAdapter.h
//  BDWebImage_Example
//
//  Created by 陈奕 on 2020/4/8.
//  Copyright © 2020 Bytedance.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <BDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDImageAdapter : NSObject

@property (nonatomic, assign) BDImageRequestOptions options;
@property (atomic, copy) NSString *record;
@property (nonatomic, assign) BOOL isPrefetch;
@property (nonatomic, assign) BOOL isCyclePlayAnim;
@property (nonatomic, assign) BOOL isRetry;
@property (nonatomic, assign) BOOL isDecodeForDisplay;
@property(nonatomic, copy) void (^recordBlock)(NSString * record);
@property (nonatomic, copy) NSDictionary<NSString *, NSArray *> * urls;

+ (instancetype)sharedAdapter;

- (void)updateCacheSize;

- (NSUInteger)cacheSize;

- (void)updateRecord:(NSString *)record;

@end

NS_ASSUME_NONNULL_END
