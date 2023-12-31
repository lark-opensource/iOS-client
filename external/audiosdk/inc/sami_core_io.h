//
// Created by jiamin zhang on 2021/6/22.
//

#ifndef SAMI_CORE_SAMI_CORE_IO_H
#define SAMI_CORE_SAMI_CORE_IO_H
#include <map>
#include <string>
#include <vector>

typedef struct SAMIDataFD {
    uint32_t fileNameIdx;
    uint32_t fileNameLen;
    uint32_t fileIdx;
    uint32_t fileLen;
} SAMIDataFD;

typedef struct SAMIDataHeader {
    unsigned char fid[8];
    uint32_t version;
    uint32_t fileCount;
    uint32_t crc32;
    struct SAMIDataFD* fds;
    std::map<std::string, uint32_t> allFilesMap;
} SAMIDataHeader;

typedef struct SAMIDecryptAllData {
    std::string fileName;
    unsigned char* fileData;
    uint32_t fileLen;
} SAMIDecryptAllData;

enum EncryptionMode {
    AES128 = 0,
    AES256 = 1,
};

class SAMICoreIOEncrypt {
private:
    const std::string dir;
    const uint32_t version;
    const EncryptionMode mode;

public:
    explicit SAMICoreIOEncrypt(std::string directory, uint32_t version,
                               EncryptionMode encMode = EncryptionMode::AES256);

    void encrypt(std::string outFile);

    static std::string normalPath(std::string path) {
        std::string normalPath;
        for(size_t i = 0; i < path.size(); i++) {
            if(path[i] == '\\' || path[i] == '/') {
#if(_WIN32)

                normalPath.push_back('\\');
#else
                normalPath.push_back('/');
#endif
                continue;
            }

            normalPath.push_back(path[i]);
        }

        return normalPath;
    }

private:
    void getAllFiles(std::string dir, std::vector<std::string>& files);

    unsigned char* encrypt(uint32_t& outLen);
};

class SAMICoreFileStream;

class SAMICoreIODecrypt {
private:
    std::string file;
    SAMIDataHeader* Dataheader = nullptr;
    SAMICoreFileStream* fileStream = nullptr;
    unsigned char* encryptData = nullptr;
    const uint32_t encryptDataLen = 0;
    bool needCheckCrc;
    int keyLen;

public:
    explicit SAMICoreIODecrypt(std::string path, bool needCheckCrc32 = false);

    explicit SAMICoreIODecrypt(unsigned char* data, const uint32_t len, bool needCheckCrc32 = false);

    unsigned char* getFile(std::string fileName, uint32_t& outLen);

    std::vector<SAMIDecryptAllData> getAllFiles();

    ~SAMICoreIODecrypt();

private:
    void decryptFromFile();

    void decryptFromMemory();

    bool verifyVersion(uint32_t version);
};

#endif  //SAMI_CORE_SAMI_CORE_IO_H
