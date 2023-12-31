//
//  NLEEditorListener.h
//  NLEPlatform
//
//  Created by bytedance on 2021/3/29.
//

#import <Foundation/Foundation.h>
#import "NLEEditor.h"
#import "NLENativeDefine.h"
#import "NLETypeConverter.h"

@protocol NLEEditorListenerDelegate <NSObject>

- (void)didChange;

@end


namespace cut::model {
    class _NLEEditorListener: public NLEEditorListener
    {
    public:
        __weak id<NLEEditorListenerDelegate> delegate;
        
        void onChanged() override
        {
            if([delegate respondsToSelector:@selector(didChange)]){
                [delegate didChange];
            }
        }
        
    };

}


NS_ASSUME_NONNULL_BEGIN

@interface NLEEditorListener_OC : NSObject

@property (nonatomic, weak) id<NLEEditorListenerDelegate> delegate;

- (std::shared_ptr<cut::model::_NLEEditorListener>)cppListener;

@end

NS_ASSUME_NONNULL_END
