//
//  IESVideoDetectHelper.h
//  IESVideoDetector
//
//  Created by geekxing on 2020/8/7.
//

#import <Foundation/Foundation.h>
#import "IESVideoDetectInputModelProtocol.h"
@class IESVideoDetectOutputModel,IESAVAsset,IESCompositionInfoModel;

NS_ASSUME_NONNULL_BEGIN

@interface IESVideoDetectHelper : NSObject

+ (IESVideoDetectOutputModel *)videoOutputModelWithVideoInput:(id<IESVideoDetectInputModelProtocol>)videoInput videoInfo:(IESAVAsset *)videoInfo;
+ (void)makeAlogWithVideoOutput:(IESVideoDetectOutputModel *)output ;
+ (IESCompositionInfoModel *)compositionModelWithOutput:(IESVideoDetectOutputModel *)output;

@end

NS_ASSUME_NONNULL_END
