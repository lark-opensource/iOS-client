#ifdef __cplusplus
#ifndef _BACH_ALGORITHM_BUFFER_H_
#define _BACH_ALGORITHM_BUFFER_H_

#include "Bach/Base/BachAlgorithmConstant.h"
#include "Bach/Algorithm/AlgorithmInfo.h"

#include "Gaia/AMGRefBase.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT BachBuffer : public AmazingEngine::RefBase
{
public:
    BachBuffer(const AlgorithmResultType& type);
    BachBuffer() = default;
    virtual ~BachBuffer() = default;

    const AlgorithmResultType& getType() const;
    void setType(const AlgorithmResultType& type);

    BachBuffer* clone() const;

    double m_timeStamp = 0;
    std::vector<AmazingEngine::SharePtr<AmazingEngine::RefBase>> m_infos;

private:
    bool _ableToClone() const;
    virtual BachBuffer* _clone() const
    {
        // check if the algorithm is able to clone
        if (!_ableToClone() || m_infos.empty())
        {
            return nullptr;
        }
        auto* buffer = new BachBuffer(m_resultType);
        buffer->m_infos.resize(m_infos.size());
        for (int i = 0; i < m_infos.size(); ++i)
        {
            auto* info = new AlgorithmInfo;
            auto* ptr = static_cast<AlgorithmInfo*>(m_infos[i].get());
            if (ptr == nullptr)
            {
                delete info;
                return nullptr;
            }
            info->copyFrom(*ptr);
            buffer->m_infos[i] = info;
        }
        buffer->m_timeStamp = m_timeStamp;
        return buffer;
    }

protected:
    AlgorithmResultType m_resultType = AlgorithmResultType::INVALID;
};

void MapBufferSerializeToString(const BachBuffer& buffer, std::string& str);
void MapBufferParseFromString(const std::string& str, BachBuffer& buffer);

NAMESPACE_BACH_END

#endif

#endif