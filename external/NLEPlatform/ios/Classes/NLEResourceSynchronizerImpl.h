//
//  NLEResourceSynchronizerImpl.h
//  Pods
//
//  Created by bytedance on 2021/1/11.
//

#ifndef NLEResourceSynchronizerImpl_h
#define NLEResourceSynchronizerImpl_h
#import "NLEResourceSynchronizerImpl+iOS.h"
#include "NLEResourceSynchronizer.h"
#include "nle_export.h"


namespace nle {
    namespace resource {
    class NLE_EXPORT_CLASS NLEResourceSynchronizerImpl : public NLEResourceSynchronizer
    {
    public:
        
        NLEResourceSynchronizerImpl();
        
        virtual ~NLEResourceSynchronizerImpl();
        
    public:
        
        /**
         * @param resourceId 输入资源ID, Uri, URS .. 等等
         * @param callback 监听器
         * @return 错误码，0 表示成功发起请求
         */
        virtual int32_t fetch(const NLEResourceId& resourceId, const std::shared_ptr<NLEResourceFetchCallback>& callback);
        /**
         * @param resourceFile 输入资源文件路径, Uri, URS .. 等等
         * @param callback 监听器
         * @return 错误码，0 表示成功发起请求
         */
        virtual int32_t push(const NLEResourceFile& resourceFile, const std::shared_ptr<NLEResourceFetchCallback>& callback);
        
        virtual void setSynchronizerImpOC(NLEResourceSynchronizerImpl_OC* SyncImplOC);
        
    private:
        NLEResourceSynchronizerImpl_OC*            m_SyncImplOC;
    };
    }
}

#endif /* NLEResourceSynchronizerImpl_h */
