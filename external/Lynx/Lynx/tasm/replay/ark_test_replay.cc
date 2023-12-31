// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/replay/ark_test_replay.h"

#include <utility>

#include "third_party/rapidjson/document.h"
#include "third_party/rapidjson/filewritestream.h"
#include "third_party/rapidjson/prettywriter.h"
#include "third_party/rapidjson/stringbuffer.h"

namespace lynx {
namespace tasm {
namespace replay {

ArkTestReplay& ArkTestReplay::GetInstance() {
  static base::NoDestructor<ArkTestReplay> instance_;
  return *instance_;
}

void ArkTestReplay::StartTest() {
  is_start_ = true;
  dump_file_.clear();
}

void ArkTestReplay::EndTest(const std::string& file_path) {
  if (!is_start_) {
    return;
  }
  auto manager = inspector_manager_wp_.lock();
  if (manager != nullptr) {
    manager->Call("SendLayoutTree", "");

    SaveDumpFile(file_path);

    // send end protocol
    manager->Call("EndReplayTest", file_path);
  }

  dump_file_.clear();
  is_start_ = false;
}

void ArkTestReplay::SetInspectorManager(
    std::shared_ptr<devtool::InspectorManager> ptr) {
  inspector_manager_wp_ = ptr;
}

// save file to be send
void ArkTestReplay::SendFileByAgent(const std::string& type,
                                    const std::string& file) {
  if (!is_start_) {
    return;
  }

  auto pair = dump_file_.find(type);
  if (pair == dump_file_.end()) {
    std::vector<std::string> vector;
    vector.push_back(file);
    dump_file_.insert(std::make_pair(type, vector));
  } else {
    pair->second.push_back(file);
  }
}

void ArkTestReplay::SaveDumpFile(const std::string& filename) {
  rapidjson::Document doc;
  rapidjson::StringBuffer strBuf;
  rapidjson::Writer<rapidjson::StringBuffer> writer(strBuf);

  writer.StartObject();
  for (auto& it : dump_file_) {
    writer.Key(it.first);
    writer.StartArray();
    std::vector<std::string> vector = it.second;
    for (auto& str : vector) {
      writer.RawValue(str.data(), str.size(), rapidjson::Type::kObjectType);
    }
    writer.EndArray();
  }
  writer.EndObject();
  doc.Parse(strBuf.GetString());

  // write to file
  auto deleter = [](std::FILE* fp) { ::fclose(fp); };
  std::unique_ptr<std::FILE, decltype(deleter)> file_ptr(
      std::fopen(filename.data(), "w"), deleter);
  if (file_ptr) {
    char write_buffer[kFileDataBufferSize];
    rapidjson::FileWriteStream os(file_ptr.get(), write_buffer,
                                  sizeof(write_buffer));
    rapidjson::Writer<rapidjson::FileWriteStream, rapidjson::UTF8<>,
                      rapidjson::UTF8<>, rapidjson::CrtAllocator,
                      rapidjson::kWriteNanAndInfFlag>
        file_writer(os);
    doc.Accept(file_writer);
  }
}
}  // namespace replay
}  // namespace tasm
}  // namespace lynx
