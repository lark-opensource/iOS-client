//
//  BDUGVideoImageShareModel.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/16.
//

#import <Foundation/Foundation.h>
#import "BDUGVideoImageShare.h"
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDUGVideoImageShareContentModel : NSObject

@property (nonatomic, strong, nullable) BDUGVideoImageShareInfo *originShareInfo;
@property (nonatomic, copy, nullable) NSString *sandboxPath;
@property (nonatomic, copy, nullable) NSString *albumIdentifier;
@property (nonatomic, strong, nullable) PHAsset *albumAsset;
@property (nonatomic, strong, nullable) UIImage *resultImage;

@end

NS_ASSUME_NONNULL_END
