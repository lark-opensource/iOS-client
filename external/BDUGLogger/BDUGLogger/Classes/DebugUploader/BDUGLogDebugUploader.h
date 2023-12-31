//
//  BDUGLogDebugUploader.h
//  Pods
//
//  Created by shuncheng on 2019/6/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDUGLogDebugUploaderCallback)(BOOL isSuccess, NSInteger fileCount);

@interface BDUGLogDebugUploader : NSObject

+ (instancetype)sharedInstance;

- (void)uploadWithTag:(NSString *)tag andCallback:(BDUGLogDebugUploaderCallback)callback;

@end

NS_ASSUME_NONNULL_END
