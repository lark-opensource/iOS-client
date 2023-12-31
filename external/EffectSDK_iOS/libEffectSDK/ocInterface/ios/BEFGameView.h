
#import <UIKit/UIKit.h>



/// message delegate
@protocol BEFGameViewMsgDelegate <NSObject>

/// process message ,return TRUE if processed, else return FALSE
/// @brief message callback
/// @param msgid message id
/// @param arg1 additional arg 1
/// @param arg2 additional arg 2
/// @param arg3 additional arg 3
/// @return return YES when success，return NO when fail
- (BOOL)msgProc :(unsigned int)msgid
           arg1 :(long)arg1
           arg2 :(long)arg2
           arg3 :(const char *)arg3;
@end



@interface BEFGameView : UIView


/// set fps, 60 by default
- (void)setFPS:(NSInteger)fps;


/// set sticker bundle
- (void)setBundleName:(NSString*)bundleName;


/// load sticker, input the path of sticker in bundle (for builtin resource)
- (BOOL)loadGamePath:(NSString*)gamePath;


/// load sticker, input absolutie path of sticker in device (for downloaded resource)
- (BOOL)loadGameFullPath:(NSString*)fullPath;


/// add/remove message delegate to outside from BEFGameView
- (void)addMessageDelegate:(id<BEFGameViewMsgDelegate>)delegate;
- (void)removeMessageDelegate:(id<BEFGameViewMsgDelegate>)delegate;


/// send message from outside to BEFGameView
- (int)sendMessage:(unsigned int)msgid arg1:(long)arg1 arg2:(long)arg2 arg3:(const char*)arg3;


/// pause/resume
- (void)onPause;
- (void)onResume;

@end
