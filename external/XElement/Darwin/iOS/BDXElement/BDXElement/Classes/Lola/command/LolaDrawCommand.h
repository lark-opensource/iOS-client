//
//  LolaDrawCommand.h
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/10/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LolaDrawContext.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * tp : type
 "fr" -> FillRectCommand()
 "ft" -> FillTextCommand()
 "st" -> StrokeTextCommand()
 "sr" -> StrokeRectCommand()
 "sta" -> StateCommand()
 "sc" -> ScaleCommand()
 "ro" -> RotateCommand()
 "ts" -> TranslateCommand()
 "tf" -> TransformCommand()
 "ps" -> PaintSettingCommand()
 "pas" -> PathControlCommand()
 "im" -> ImageCommand()
 "cr" -> ClearRectCommand()
 "cp" -> ClipCommand()
 "id" -> ImageDataCommand()
 *
 */

@interface LolaDrawCommand : NSObject

@property (nonatomic, copy, readonly) NSString *typeStr;

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context;

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context;

- (void)recycle;

@end

NS_ASSUME_NONNULL_END
