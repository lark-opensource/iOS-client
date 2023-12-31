//
//  HMUploader.h
//  Hermas
//
//  Created by 崔晓兵 on 6/1/2022.
//

#import <Foundation/Foundation.h>

#include "iuploader.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HMNetworkProtocol;

namespace hermas {

class HMUploader : public IUploader {
public:
    static void RegisterCustomNetworkManager(id<HMNetworkProtocol> networkManager);
    
public:
    HMUploader();
    ~HMUploader();
    
    virtual std::shared_ptr<ResponseStruct> Upload(RequestStruct& request) override;
    
    void UploadSuccess(const std::string& module_id) override;
    
    void UploadFailure(const std::string& module_id) override;
    
private:
    id<HMNetworkProtocol> GetNetworkManager();
    id<HMNetworkProtocol> GetURLSessionManager();
    
private:
    static id<HMNetworkProtocol> m_customNetworkManager;
};

}

NS_ASSUME_NONNULL_END
