//
//  DVETextReaderModelProtocol.h
//  NLEEditor
//
//  Created by bytedance on 2021/5/27.
//

#import <Foundation/Foundation.h>
#import "DVEResourceModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVETextReaderModelProtocol <DVEResourceModelProtocol>

@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) NSInteger rate;
@property (nonatomic, copy) NSString *ttsVoice;
@property (nonatomic, copy) NSString *typeName;
@property (nonatomic, assign) BOOL isNone;

@end

NS_ASSUME_NONNULL_END
