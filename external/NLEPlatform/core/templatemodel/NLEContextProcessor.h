//
//  NLEContextProcessor.hpp
//  NLEPlatform
//
//  Created by Lemonior on 2021/10/25.
//

#ifndef NLEContextProcessor_hpp
#define NLEContextProcessor_hpp

#ifdef __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLENodeDecoder.h>
#include <NLEPlatform/NLENode.h>
#include <NLEPlatform/NLESequenceNode.h>
#else
#include <NLENodeDecoder.h>
#include <NLENode.h>
#include <NLESequenceNode.h>
#endif

namespace cut::model {

    class NLE_EXPORT_CLASS NLEContextProcessorFunc {
        public:
            virtual ~NLEContextProcessorFunc() = default;

            /**
             * 加密
             * context: 待加密信息
             */
            virtual std::string encrypt(const std::string &context) = 0;

            /**
             * 解密
             * contextPath: 待解密文件路径
             */
            virtual std::string decrypt(const std::string &contextPath) = 0;
    };

    /**
     * 资源处理器基类
     */
    class NLE_EXPORT_CLASS NLEContextProcessor {
        
        private:
    
            mutable std::shared_ptr<cut::model::NLEContextProcessorFunc> _delegate;

        
        public:
            // 获取单例
            static const NLEContextProcessor * processor();
            
            /**
             * 加密
             * context: 待加密信息
             */
            std::string encrypt(const std::string &context) const;
        
            /**
             * 解密
             * contextPath: 待解密文件路径
             */
            std::string decrypt(const std::string &contextPath) const;
        
            // 设置转换器代理
            void setDelegate(const std::shared_ptr<cut::model::NLEContextProcessorFunc>& delegate) const {
                _delegate = delegate;
            }
    };
}

#endif /* NLEContextProcessor_hpp */
