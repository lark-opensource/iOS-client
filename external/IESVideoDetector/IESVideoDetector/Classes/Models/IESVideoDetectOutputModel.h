//
//  IESVideoDetectOutputModel.h
//  IESVideoDebug
//
//  Created by geekxing on 2020/5/15.
//

#import <Foundation/Foundation.h>
#import "IESAVAsset.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESAVAsset (IESVideoDebug)

@property (nonatomic, copy, readonly) NSDictionary *formattedDict;
- (NSArray *)sortedFormattedKeys;

@end

@interface IESVideoDetectOutputModel : NSObject

@property (nonatomic, copy) NSString *assetClazz;
@property (nonatomic, copy, readonly) NSDictionary *formattedDict;
@property (nonatomic, copy) NSDictionary *debugExtraDict;
- (void)makeOutput:(void (^)(NSMutableDictionary *dict))makeOutputBlock;
- (NSArray *)sortedFormattedKeys;

@end

NS_ASSUME_NONNULL_END
