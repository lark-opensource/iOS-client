//
// Created by admin on 2020/7/23.
//

#pragma once
#include "ae_effect.h"

namespace Jukedeck {
namespace MusicDSP {
namespace Processors {
class IProcessor;
}
}  // namespace MusicDSP
}  // namespace Jukedeck

namespace mammon {

using namespace Jukedeck::MusicDSP;

class MDSPProcessorEffect : public Effect {
public:
    explicit MDSPProcessorEffect(std::unique_ptr<Jukedeck::MusicDSP::Processors::IProcessor>& mdsp_processor);

    // MDSPProcessorEffect& operator=(std::unique_ptr<Jukedeck::MusicDSP::Processors::IProcessor>& mdsp_processor);

    const char* getName() const override;

    void reset() override;

    int process(std::vector<Bus>& bus_array) override;

    void prepare(double sample_rate, int max_block_size);

    bool isPrepared() const;

    void setParameter(const std::string& name, float value) override;

    static std::unique_ptr<MDSPProcessorEffect> create(const std::string& proc_name);

    static bool isMDSPProcessor(const std::string& proc_name);

private:
    class Impl;
    std::shared_ptr<Impl> impl_;
};
}  // namespace mammon
