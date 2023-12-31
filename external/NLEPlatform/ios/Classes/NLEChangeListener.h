//
//  NLEChangeListener.h
//  NLEPlatform
//
//  Created by bytedance on 2021/3/29.
//

#import <Foundation/Foundation.h>
#import "NLENode.h"

@protocol NLEChangeListenerDelegate <NSObject>

- (void)didChange;

@end


namespace cut::model {
    class _NLEChangeListener: public NLEChangeListener
    {
    public:
        __weak id<NLEChangeListenerDelegate> delegate;
        
        void onChanged() override
        {
            [delegate didChange];
        }
    };

}


NS_ASSUME_NONNULL_BEGIN

@interface NLEChangeListener : NSObject

@property (nonatomic, weak) id<NLEChangeListenerDelegate> delegate;

- (std::shared_ptr<cut::model::_NLEChangeListener>)cppListener;

@end

NS_ASSUME_NONNULL_END
