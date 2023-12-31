//
// Created by bytedance on 2020/12/11.
//

#ifndef NLEMODEL_NLENODECHANGEINFO_H
#define NLEMODEL_NLENODECHANGEINFO_H

#include "nle_export.h"
#include "NLENode.h"
#include <memory>

namespace cut::model {

    enum class ChangeBit : uint64_t {
        NONE = 0,         // 无变更
        PROPERTY = 1,     // primaryValues 变更
        CHILD = 2,        // nleObjectMap 变更
        EXTRA = 4,        // extraMap 变更
    };

    inline constexpr uint64_t operator| (ChangeBit a, ChangeBit b) {
        return static_cast<uint64_t>(a) | static_cast<uint64_t>(b);
    }

    inline constexpr uint64_t operator& (ChangeBit a, ChangeBit b) {
        return static_cast<uint64_t>(a) & static_cast<uint64_t>(b);
    }

    class NLE_EXPORT_CLASS ChangeBits {
    private:
        uint64_t changeBits = static_cast<uint64_t>(ChangeBit::NONE);
    public:
        bool hasChange() const {
            return changeBits != static_cast<uint64_t>(ChangeBit::NONE);
        }
        bool hasChange(ChangeBit bit) const {
            return (changeBits & static_cast<uint64_t>(bit)) == static_cast<uint64_t>(bit);
        }
        void markChange(ChangeBit bit) {
            changeBits |= static_cast<uint64_t>(bit);
        }
        void unmarkChange(ChangeBit bit) {
            changeBits &= ~static_cast<uint64_t>(bit);
        }
        void clearChange() {
            changeBits = static_cast<uint64_t>(ChangeBit::NONE);
        }
        std::string toString() const {
            std::string s;
            if (hasChange(ChangeBit::PROPERTY)) {
                s += "PROP|";
            }
            if (hasChange(ChangeBit::CHILD)) {
                s += "CHILD|";
            }
            if (hasChange(ChangeBit::EXTRA)) {
                s += "EXTRA|";
            }
            if (s.empty()) {
                return "NONE";
            } else {
                return s;
            }
        }
    };

}

#endif //NLEMODEL_NLENODECHANGEINFO_H
