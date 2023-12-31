#include "quickjs/heapprofiler/include/take-snapshot.h"

#include <iostream>

#include "quickjs/heapprofiler/include/gen.h"
#include "quickjs/heapprofiler/include/heapprofiler.h"
#include "quickjs/heapprofiler/include/serialize.h"

namespace quickjs {
namespace heapprofiler {

class PrintFronted : public Fronted {
 public:
  // send notification
  virtual void AddHeapSnapshotChunk(const std::string& chunk) override {
    stream << chunk;
  }

  virtual void ReportHeapSnapshotProgress(uint32_t done, uint32_t total,
                                          bool finished) override{};
  // send reponse
  virtual void SendReponse(LEPUSValue message) override{};

  const std::stringstream& GetStream() { return stream; }

  virtual ~PrintFronted() { stream.clear(); }

 private:
  std::stringstream stream;
};

}  // namespace heapprofiler
}  // namespace quickjs

using namespace quickjs::heapprofiler;
void lepus_profile_take_heap_snapshot(LEPUSContext* ctx) {
  auto outstream = std::make_shared<PrintFronted>();

  GetQjsHeapProfilerImplInstance().TakeHeapSnapshot(ctx, outstream);

  lepus_heap_dump_file(outstream->GetStream().str(), "heapsnapshot");
}

// for unittest
#ifdef HEAPPROFILER_UNITTEST
void take_heap_snapshot_test(LEPUSContext* ctx) {
  auto outstream = std::make_shared<PrintFronted>();

  GetQjsHeapProfilerImplInstance().TakeHeapSnapshot(ctx, outstream);
}
#endif
