//
//  IESVideoInspector.h
//  IESVideoDebug
//
//  Created by geekxing on 2020/5/21.
//

#import <Foundation/Foundation.h>
#import "IESVideoDetectInputModelProtocol.h"
@class IESVideoDetectOutputModel,IESCompositionInfoModel;
typedef void(^IESVideoInspectionCallback)(IESVideoDetectOutputModel *output);

@interface IESVideoInspector : NSObject
@property (nonatomic, assign) BOOL enabled; // default is NO.
+ (instancetype)shared;
- (void)inspectVideo:(id<IESVideoDetectInputModelProtocol>)videoInput;
- (void)inspectVideo:(id<IESVideoDetectInputModelProtocol>)videoInput callback:(IESVideoInspectionCallback)callback;

@end

