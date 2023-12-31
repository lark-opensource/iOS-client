//
//  NLEBranchListener.h
//  NLEPlatform
//
//  Created by bytedance on 2021/3/15.
//

#import <Foundation/Foundation.h>
#import "NLEBranch.h"

@protocol NLEBranchListenerDelegate <NSObject>

- (void)branchDidChange;

@end


namespace cut::model {
    class _NLEBranchListener: public NLEBranchListener
    {
    public:
        __weak id<NLEBranchListenerDelegate> delegate;
        
        void onChanged() override
        {
            [delegate branchDidChange];
        }
    };

}


NS_ASSUME_NONNULL_BEGIN

@interface NLEBranchListener : NSObject

@property (nonatomic, weak) id<NLEBranchListenerDelegate> delegate;

- (std::shared_ptr<cut::model::_NLEBranchListener>)cppListener;

@end

NS_ASSUME_NONNULL_END
