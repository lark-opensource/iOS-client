//
//  SceneCut.h

#import <UIKit/UIKit.h>
#import "VFMetalContext.h"
@interface SceneCut : NSObject
-(instancetype)initWithContext: (VFMetalContext *) sharedcontext;
-(BOOL)IsSceneCut:(void*)img1  img_ref:(void*)img2 intype:(int) intype;
-(void)Release;
@end
