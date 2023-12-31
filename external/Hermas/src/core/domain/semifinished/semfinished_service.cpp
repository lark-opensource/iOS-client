//
//  semfinished_service.cpp
//  Hermas
//
//  Created by liuhan on 2022/3/31.
//

#include "semfinished_service.h"
#include "protocol_service.h"
#include "mmap_write_file.h"
#include "file_service.h"
#include "time_util.h"
#include "file_util.h"
#include "string_util.h"

namespace hermas {

static const char* SemiServiceTag = "Hermas_SemiService";

SemifinishedService::SemifinishedService(const std::shared_ptr<Env>& env, bool should_new)
    : m_env(env)
{
    if (should_new) {
        NewSemiFile(1024 * 1024);
    }
}

void SemifinishedService::NewSemiFile(int file_size) {
    // gen file path
    FilePath file_path = GenSemiDirPath().Append("10000_" + TO_STRING(CurTimeMillis()) + "_");
    // new semifinished mmap instance
    m_semi_file_id = std::make_unique<SemiMmapFile>(file_path);
    // new mmap file
    bool ret = m_semi_file_id->CreatSemiFile();
    if (!ret) {
        // First failure was because no matched dir
        FilePath semi_dir = GenSemiDirPath();
        if (!Mkdirs(semi_dir)) {
            logd(SemiServiceTag, "mkdir parent path failed: %s", semi_dir.sstrValue().c_str());
        }
        ret = m_semi_file_id->CreatSemiFile();
        if (!ret) {
            // 构建失败，则返回 0
            // TODO monitor
            loge(SemiServiceTag, "new file fail ! file %s", file_path.sstrValue().c_str());
        }
    }
}

void SemifinishedService::StartTraceRecord(const std::string &data, const std::string &traceID) {
    if (data.empty()) {
        logw(SemiServiceTag, "Start Trace: The Started trace is nil. TraceID = %s", traceID.c_str());
        return;
    }
    if (isValidTrace(traceID)) {
        bool ret = m_semi_file_id->WriteSemiRecord(data, traceID, "", true);
        if (!ret) {
            logw(SemiServiceTag, "Start: Write trace failed. traceID = %s", traceID.c_str());
        }
    }
}

void SemifinishedService::StartSpanRecord(const std::string &data, const std::string &traceID, const std::string &spanID) {
    if (data.empty()) {
        logw(SemiServiceTag, "Start Span: The started span is nil. SpanID = %s", spanID.c_str());
        return;
    }
    if (isValidSpan(traceID, spanID)) {
        bool ret = m_semi_file_id->WriteSemiRecord(data, traceID, spanID, false);
        if (!ret) {
            logw(SemiServiceTag, "Start: Write span failed. traceID = %s && spanID = %s", traceID.c_str(), spanID.c_str());
        }
    }
}

void SemifinishedService::FinishTraceRecord(const std::string& data, const std::string& traceID, const std::string& spanIDList) {
    if (data.empty()) {
        logw(SemiServiceTag, "Finish Trace: The finished trace is nil. TraceID = %s", traceID.c_str());
        return;
    }
    
    if (!isValidTrace(traceID)) {
        logw(SemiServiceTag, "Finish Trace: The type of finished trace err. TraceID = %s", traceID.c_str());
        return;
    }
    
    std::vector<std::string> spanIDVec = SplitStringPiece(spanIDList, "_", WhitespaceHandling::TRIM_WHITESPACE, SplitResult::SPLIT_WANT_NONEMPTY);
    
    FilePath file_path = GenSemi2ReadyFile(m_semi_file_id->m_file_path);
    std::unique_ptr<MmapWriteFile> prepare_file_writer = GenerateNormalMmapFileWriter(file_path);
    if (prepare_file_writer == nullptr) {
        loge(SemiServiceTag, "Finish Trace: Create prepare mmap file failed. TraceID = %s", traceID.c_str());
        return;
    }
    // write new trace record
    bool ret = prepare_file_writer->Write(data.c_str(), (int32_t)data.length());
    if (!ret) {
        logw(SemiServiceTag, "Finish Trace: Write finished trace err. Abandon the trace and  TraceID = %s", traceID.c_str());
        prepare_file_writer->CloseFile();
        RemoveFile(file_path);
        return;
    }
    
    // delete original trace
    ret = m_semi_file_id->DeleteSemiRecord(traceID, true);
    if (!ret) {
        logw(SemiServiceTag, "Finish Trace: Delete finished trace err. TraceID = %s", traceID.c_str());
    }
    
    for (auto& spanID: spanIDVec) {
        if (!isValidSpan(traceID, spanID)) {
            logw(SemiServiceTag, "Finish Trace: The type of finished span err. SpanID = %s", spanID.c_str())
            continue;
        }
        std::string spanRecord = m_semi_file_id->ReadAndDeleteSemiRecord(spanID, false);
        if (spanRecord.empty()) {
            logw(SemiServiceTag, "Finish Trace: The span is nil. TraceID = %s && SpanID = %s", traceID.c_str(), spanID.c_str());
            continue;
        }
        ret = prepare_file_writer->Write(spanRecord.c_str(), spanRecord.length());
        if (!ret) {
            logw(SemiServiceTag, "Finish Trace: Write span failed. TraceID = %s && SpanID = %s && span = %s", traceID.c_str(), spanID.c_str(), spanRecord.c_str());
        }
    }
    
    prepare_file_writer->CloseFile();
    MoveSemi2ReadyFile(file_path);
}

void SemifinishedService::FinishSpanRecord(const std::string &data, const std::string &traceID, const std::string &spanID) {
    if (data.empty()) {
        logw(SemiServiceTag, "Finish Span: The finished span is nil. TraceID = %s && Span = %s", traceID.c_str(), spanID.c_str());
        return;
    }
    
    if (!isValidSpan(traceID, spanID)) {
        logw(SemiServiceTag, "Finish Span: The type of finished span is invalid. TraceID = %s && Span = %s", traceID.c_str(), spanID.c_str());
        return;
    }
    
    // delete old span
    bool ret = m_semi_file_id->DeleteSemiRecord(spanID, false);
    if (!ret) {
        logd(SemiServiceTag, "Finish Span: delete span failed. TraceID = %s && SpanID = %s", traceID.c_str(), spanID.c_str());
    }
    // insert new span
    ret = m_semi_file_id->WriteSemiRecord(data, traceID, spanID, false);
    if (!ret) {
        logw(SemiServiceTag, "Finish Span: Write span failed. traceID = %s && spanID = %s", traceID.c_str(), spanID.c_str());
    }
    
}

void SemifinishedService::DeleteRecords(const std::string& traceID, const std::string& spanIDList) {
    // 处理trace
    if (!isValidTrace(traceID)) return;
    bool ret = m_semi_file_id->DeleteSemiRecord(traceID, true);
    if (!ret) {
        logd(SemiServiceTag, "Delete: delete trace failed. TraceID = %s", traceID.c_str());
        return;
    }
    
    std::vector<std::string> spanIDVec = SplitStringPiece(spanIDList, "_", WhitespaceHandling::TRIM_WHITESPACE, SplitResult::SPLIT_WANT_NONEMPTY);
    
    // 处理span
    for (auto& spanID : spanIDVec) {
        if (!isValidSpan(traceID, spanID)) continue;
        ret = m_semi_file_id->DeleteSemiRecord(spanID, false);
        if (!ret) {
            logd(SemiServiceTag, "Delete: delete span failed. TraceID = %s && SpanID = %s", traceID.c_str(), spanID.c_str());
        }
    }
}

bool SemifinishedService::isValidTrace(const std::string &traceID) {
    if (traceID.empty()) {
        loge(SemiServiceTag, "Inserted traceID is nil. traceID = %s", traceID.c_str());
        return false;
    }
    if (traceID.length() != SEMITRACEIDLEN) {
        loge(SemiServiceTag, "The length of traceID is not %d. traceID = %s", SEMITRACEIDLEN, traceID.c_str());
        return false;
    }
    return true;
}

bool SemifinishedService::isValidSpan(const std::string &traceID, const std::string &spanID) {
    if (spanID.empty()) {
        loge(SemiServiceTag, "Inserted spanID is nil. traceID = %s, spanID = %s", traceID.c_str(), spanID.c_str());
        return false;
    }
    if (spanID.length() != SEMISPANIDLEN) {
        loge(SemiServiceTag, "The length of spanID is not %d. traceID = %s, spanID = %s", SEMISPANIDLEN, traceID.c_str(), spanID.c_str());
        return false;
    }
    bool ret = isValidTrace(traceID);
    return ret;
}

void SemifinishedService::LaunchReportForSemi() {
    std::unique_ptr<SemiMmapFile> semi_file_reader = nullptr;
    std::unique_ptr<MmapWriteFile> prepare_file_writer = nullptr;
    // 遍历semi目录下所有文件，并依据traceID将属于写入新文件
    std::vector<FilePath> semi_files_name = GetFilesName(GenSemiDirPath(), FileSysType::kOnlyFile);
    for (auto& semi_file_name: semi_files_name) {
        std::string createTimeOfFile = semi_file_name.strValue().substr(semi_file_name.strValue().find_first_of("_"), semi_file_name.strValue().find_last_of("_"));
        
        // skip current file
        if (m_semi_file_id != nullptr && m_semi_file_id->m_file_path.strValue().find(createTimeOfFile) != std::string::npos) {
            continue;
        }
        
        FilePath semi_file_path = GenSemiDirPath().Append(semi_file_name);
        if (semi_file_name.strValue().back() != '_') {
            MoveSemi2ReadyFile(semi_file_path);
            continue;
        }
        semi_file_reader = GenerateSemiMmapFileReader(semi_file_path);
        if (semi_file_reader == nullptr) continue;
        
        // build traceID MAP
        int32_t fileOffset = 0;
        std::map<std::string, std::vector<int32_t>> traceIDMap;
        while (fileOffset < semi_file_reader->m_file_len) {
            int32_t blockOffset = fileOffset;
            bool isUse = semi_file_reader->ReadBlockIsUse(blockOffset);
            blockOffset += SEMIISUSELEN;
            int32_t block_len = semi_file_reader->ReadBlockLen(blockOffset);
            if (block_len == 0) {
                loge(SemiServiceTag, "Launch Report Read: The length of block is 0");
                break;
            }
            if (!isUse) {
                fileOffset += block_len;
                continue;
            } else {
                int32_t record_len = block_len - SEMIRECORDHEADERLEN;
                if (record_len == 0) {
                    fileOffset += block_len;
                    continue;
                }
                blockOffset += SEMIBLOCKLENLEN;
                std::string traceID = semi_file_reader->ReadSemiTraceID(blockOffset);
                if (traceID.empty()) continue;
                
                blockOffset += SEMITRACEIDLEN;
                std::map<string, std::vector<int32_t>>::iterator iter = traceIDMap.find(traceID);
                if (iter != traceIDMap.end()) {
                    // traceID 已存在
                    traceIDMap[traceID][0] += record_len;
                    traceIDMap[traceID].push_back(fileOffset);
                } else {
                    // traceID 未存在
                    std::vector<int32_t> msg_vec;
                    msg_vec.push_back(record_len);
                    msg_vec.push_back(fileOffset);
                    traceIDMap[traceID]= msg_vec;
                }
                fileOffset += block_len;
            }
        }
        
        if (traceIDMap.size() == 0) {
            semi_file_reader->CloseSemiFile();
            RemoveFile(semi_file_path);
        }
        
        std::map<string, std::vector<int32_t>>::iterator iter;
        bool isSuccess = false;
        for (iter = traceIDMap.begin(); iter != traceIDMap.end(); iter++) {
            if (prepare_file_writer == nullptr) {
                FilePath to_prepare_path = GenSemi2ReadyFile(semi_file_reader->m_file_path);
                prepare_file_writer = GenerateNormalMmapFileWriter(to_prepare_path);
                if (prepare_file_writer == nullptr) {
                    loge(SemiServiceTag, "Launch Report: Create prepare file writer failed. file path = %s", to_prepare_path.strValue().c_str());
                    break;
                }
            }
            if (!prepare_file_writer->CheckFileSizeExcludeFirstRecord(iter->second[0])) {
                prepare_file_writer->CloseFile();
                MoveSemi2ReadyFile(prepare_file_writer->GetFilePath());
                prepare_file_writer = nullptr;
                
                FilePath to_prepare_path = GenSemi2ReadyFile(semi_file_reader->m_file_path);
                prepare_file_writer = GenerateNormalMmapFileWriter(to_prepare_path);
                if (prepare_file_writer == nullptr) {
                    loge(SemiServiceTag, "Launch Report: Create prepare file writer failed. file path = %s", to_prepare_path.strValue().c_str());
                    break;
                }
            }
            for (int i = 1; i < iter->second.size(); i++) {
                int32_t offset = iter->second[i];
                offset += SEMIISUSELEN;
                int32_t record_len = semi_file_reader->ReadBlockLen(offset);
                record_len -= SEMIRECORDHEADERLEN;
                offset += SEMIRECORDHEADERLEN - SEMIISUSELEN;
                std::string record = semi_file_reader->ReadSemiRecord(offset, record_len);
                prepare_file_writer->Write(record.c_str(), record_len);
            }
            isSuccess = true;
        }
        if (isSuccess) {
            semi_file_reader->CloseSemiFile();
            RemoveFile(semi_file_path);
        }
        
    }
    if (prepare_file_writer != nullptr) {
        prepare_file_writer->CloseFile();
        MoveSemi2ReadyFile(prepare_file_writer->GetFilePath());
        prepare_file_writer = nullptr;
    }
}

std::unique_ptr<SemiMmapFile> SemifinishedService::GenerateSemiMmapFileReader(const FilePath &file_path) {
    std::unique_ptr<SemiMmapFile> file_reader = std::make_unique<SemiMmapFile>(file_path);
    bool file_open = file_reader->OpenSemiFile();
    if (!file_open) {
        loge(SemiServiceTag, "Read File: Open history file failed. file path = %s", file_path.strValue().c_str());
        RemoveFile(file_path);
        return nullptr;
    }
    return file_reader;
}

std::unique_ptr<MmapWriteFile> SemifinishedService::GenerateNormalMmapFileWriter(const FilePath &file_path) {
    auto file_writer = std::make_unique<MmapWriteFile>(file_path);
    std::string record_header = ProtocolService::GenRecordHead(m_env);
    bool ret = file_writer->CreateWriteFile(MmapFile::FILE_TYPE_NORMAL, Env::ERecordEncryptVer::NONE, GlobalEnv::GetInstance().GetMaxReportSize());
    if (!ret) {
        loge(SemiServiceTag, "Write File: Generate mmap writer failed. file path = %s", file_path.strValue().c_str());
        return nullptr;
    }
    ret = file_writer->Write(record_header.c_str(), (int32_t)record_header.length());
    if (!ret) {
        loge(SemiServiceTag, "Write File: Write header failed. file path = %s", file_path.strValue().c_str());
        return nullptr;
    }
    return file_writer;
}

const FilePath SemifinishedService::GenSemiDirPath() {
    return GlobalEnv::GetInstance().GetRootPathName()
        .Append(m_env->GetModuleId())
        .Append("semifinished")
        .Append(m_env->GetAid());
}

FilePath SemifinishedService::GenSemi2ReadyFile(const FilePath &file_path) {
    auto base_name = "10000_" + TO_STRING(CurTimeMillis()) + "_" + TO_STRING(m_id++) + "_" + m_env->GetPid() + "_" + CHAR_LITERAL("0");
    return file_path.DirName().Append(base_name);
}

void SemifinishedService::MoveSemi2ReadyFile(const FilePath &file_path) {
    auto ready_dir = GenReadyDirPath(m_env->GetModuleEnv());
    FilePath target_path = ready_dir.Append(file_path.DirName().BaseName()).Append("10000").Append(file_path.BaseName());
    RenameFile(file_path, target_path);
}

void SemifinishedService::RemoveSemiFiles() {
    m_semi_file_id->CloseSemiFile();
    m_semi_file_id->FreeSemiFile();
    m_semi_file_id = nullptr;
    
}

}
