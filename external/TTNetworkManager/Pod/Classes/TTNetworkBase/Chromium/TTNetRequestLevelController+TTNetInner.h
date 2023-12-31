//
//  TTNetRequestLevelController+TTNetInner.h
//  TTNetworkManager
//
//  Created by coricpat on 2021/11/11.
//

// These methods are called with SDK internal class,
// notice that TTNetRequestLevelController is only
// enabled when TTRequestDispatcher disabled.

#ifndef TTNetRequestLevelController_TTNetInner_h
#define TTNetRequestLevelController_TTNetInner_h

@interface TTNetRequestLevelController(TTNetInner)

#ifndef DISABLE_REQ_LEVEL_CTRL

-(BOOL)isRequestLevelControlEnabled;

-(int)getLevelForRequestPath:(NSString*)path;

-(BOOL)maybeAddP1Task:(TTHttpTask*)httpTask;

-(void)notifyTaskCancel:(TTHttpTask*)httpTask;

-(void)notifyTaskFinish:(TTHttpTask*)httpTask;

-(void)getReqCtlConfig:(NSDictionary*)data;

#endif

@end


#endif /* TTNetRequestLevelController_TTNetInner_h */
