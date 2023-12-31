//
//  IESFalconHelper.m
//  Pods
//
//  Created by 陈煜钏 on 2019/9/20.
//

#import "IESFalconHelper.h"

#import "NSString+IESFalconConvenience.h"

NSData * _Nullable IESFalconGetDataFromLocalFilePaths (NSArray<NSString *> *localFilePaths, NSError **error)
{
    if (localFilePaths.count == 0) {
        return nil;
    }
    
    NSData *resourceData = nil;
    __block NSError *readError = nil;
    NSDataReadingOptions readingOptions = NSDataReadingMappedIfSafe | NSDataReadingUncached;
    
    if (localFilePaths.count > 1) {
        __block BOOL mimeValid = NO;
        [localFilePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            mimeValid = path.ies_comboAllowExtention;
            *stop = !mimeValid;
        }];
        
        if (mimeValid) {
            __block NSMutableData *httpConcatContent = [[NSMutableData alloc] init];
            [localFilePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
                NSData *fileData = [NSData dataWithContentsOfFile:path
                                                          options:readingOptions
                                                            error:&readError];
                if (readError) {
                    *stop = YES;
                }
                [httpConcatContent appendData:fileData];
            }];
            resourceData = readError ? nil : httpConcatContent;
        }
    } else {
        resourceData = [NSData dataWithContentsOfFile:localFilePaths.firstObject
                                              options:readingOptions
                                                error:&readError];
    }
    
    if (readError && error) {
        NSString *errorMessage = [NSString stringWithFormat:@"【%zd】%@",
                                  readError.code, readError.localizedDescription ? : @"Unknown"];
        *error = [NSError errorWithDomain:@"IESFalconErrorDomain"
                                     code:101
                                 userInfo:@{ NSLocalizedDescriptionKey : errorMessage }];
    }
    
    return resourceData;
}
