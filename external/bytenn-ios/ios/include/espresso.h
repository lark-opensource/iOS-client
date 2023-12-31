#ifndef ESPRESSO_API_ESPRESSO_H_
#define ESPRESSO_API_ESPRESSO_H_

#ifdef __cplusplus

#include <string>
#include <vector>
#include <map>

namespace espresso {

    class Net;

#ifdef _WIN32
#define ESPRESSO_EXPORT
#define ESPRESSO_LOCAL
#else
#define ESPRESSO_EXPORT __attribute__((visibility("default")))
#define ESPRESSO_LOCAL __attribute__((visibility("hidden")))
#endif

    struct ESPRESSO_EXPORT LayerOutput {
        void *data;
        int num;
        int width;
        int height;
        int channel;
        int type; // data type
        int fl; // fraction length


        explicit LayerOutput(void *data, int num, int width, int height, int channel,
                             int type, int fl) : data(data), num(num), width(width),
                                                 height(height), channel(channel),
                                                 type(type), fl(fl) {
        }

        int Count() {
            return num * width * height * channel;
        }

        int Offset(int n, int w, int h, int c) {
            return (n * (width * height * channel) + h * (width * channel) + w * channel) + c;
        }
    };

    enum class TextureType: int {
        Texture_CVPixelBuffer = 0,
        Texture_MTLTexture = 1,
        Texture_MTLBuffer = 2,
    };

    enum class TextureFormat {
        RGBA = 0,
        RGB = 1,
        RG = 2,
        R = 3,
    };

    enum class TextureDataType {
        Texture_U8 = 0,
        Texture_Int16 = 1,
        Texture_Uint16 = 2,
        Texture_Int32 = 3,
        Texture_Float = 4,
        Texture_Half = 5,
    };

    struct TextureLayerOutput {
        std::string name;
        void *texturePtr;
        int textureId;
        int num;
        int width;
        int height;
        int channel;
        TextureType type;
        TextureDataType dataType;
        TextureFormat format;

        explicit TextureLayerOutput(void *texturePtr, int textureId,
                                    int num, int width, int height, int channel)
            : texturePtr(texturePtr), textureId(textureId), num(num),
              width(width), height(height), channel(channel){}
    };

    class ESPRESSO_EXPORT Thrustor {
    public:
        explicit Thrustor();

        // You should set the output layer names in case the memory have been cycled used.
        int CreateNet(const std::string &net,
                      void *param,
                      std::vector<std::string> &layer_out_names);

        // Input image should be resized as the network settings, DON'T USE.
        int SetInput(const std::string layer_name, void *data, int data_size,
                     int width, int height);

        int ReInferShape(int width, int height);


        int Inference();

        // No need to release the returned data
        LayerOutput Extract(const std::string &layer_name);

        virtual ~Thrustor();

        int getLayers();

        void setThreads(int nums);

        int SkipLayer(const std::string layer_name);

        void VerifyNetParamters();

        int GetWeightLen();

        /**
         * Default output is the last layer.
         * If you don't set output layer name, you can use this to simplify the change.
         * @return if error, LayerOutput will null data.
         */
        LayerOutput getOutput();

        void InferenceBenchmark(int times);

    private:
        friend void ThrustorEnforceCPURuntime(Thrustor *thrustor);
        friend void ThrustorDefaultInSize(Thrustor *thrustor, int &height, int &width);
        friend LayerOutput ThrustorGetInput(Thrustor *thrustor);
        friend void ThrustorReset(Thrustor *thrustor);
        friend int ThrustorGetEarlyStop(Thrustor *thrustor);
        friend int ThrustorReInferShape(Thrustor *thrustor, std::vector<std::vector<int>> input_shapes) ;
        friend void GetGPUType(Thrustor *thrustor,std::vector<std::string>&gpuInfo);
        friend std::string GetCurrentCPUType(bool check_open);
        Net *handler_;
    public:
        // edge customize
        int SetSubNet(const std::vector<TextureLayerOutput> *input, const std::vector<TextureLayerOutput> *output);
    };

    ESPRESSO_EXPORT void ThrustorEnforceCPURuntime(Thrustor *thrustor);
    ESPRESSO_EXPORT void ThrustorDefaultInSize(Thrustor *thrustor, int &height, int &width);
    ESPRESSO_EXPORT LayerOutput ThrustorGetInput(Thrustor *thrustor);
    ESPRESSO_EXPORT void ThrustorReset(Thrustor *thrustor);
    ESPRESSO_EXPORT int ThrustorGetEarlyStop(Thrustor *thrustor);
    ESPRESSO_EXPORT int ThrustorReInferShape(Thrustor *thrustor, std::vector<std::vector<int>> input_shapes);

    enum ErrorCode {
        ESPRESSO_NO_ERROR = 0,
        ESPRESSO_ERR_UNEXPECTED = -1,
        ESPRESSO_EARLY_STOP = 1,
    };
}

#endif

#endif // ESPRESSO_API_ESPRESSO_H_
