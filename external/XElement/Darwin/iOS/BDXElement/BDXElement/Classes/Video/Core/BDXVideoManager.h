//
//  BDXVideoManager.h
//  BDXElement
//
//  Created by yuanyiyang on 2020/4/23.
//

#import <Foundation/Foundation.h>
#import "BDXVideoPlayerProtocol.h"
#import "BDXVideoPlayerVideoModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDXVideoPlayerVideoModelConverter <NSObject>

@optional
- (nullable BDXVideoPlayerVideoModel *)convertFromJSONDict:(NSDictionary *)jsonDict;

@end

@protocol BDXVideoManagerDelegate <NSObject>

@required

- (BDXVideoPlayerVideoModel *)convertFromJSONDict:(NSDictionary *)jsonDict;

@end

@interface BDXVideoManager : NSObject

@property (nonatomic, class, copy) Class videoCorePlayerClazz;
@property (nonatomic, class, copy) Class videoModelConverterClz;
@property (nonatomic, class, copy) Class fullScreenPlayerClz;
@property (nonatomic, class) id<BDXVideoManagerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
