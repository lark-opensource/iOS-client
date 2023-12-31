#include <jni.h>
#include <string.h>
#include "JPEG.h"

JNIEXPORT jboolean JNICALL
Java_com_larksuite_tool_image_JPEGTool_isJPEG(
        JNIEnv* env,
        jobject obj __unused, /* this */
        jbyteArray data) {
    const int length = (*env)->GetArrayLength(env, data);
    unsigned char* image_buffer = (unsigned char*)malloc(sizeof(length));
    (*env)->GetByteArrayRegion(env, data, 0, length, (jbyte *)(image_buffer));
    BOOL isjpeg = is_jpeg(image_buffer, length);
    free(image_buffer);
    return isjpeg == 1;
}

JNIEXPORT jint JNICALL
Java_com_larksuite_tool_image_JPEGTool_getJpegQuality(
        JNIEnv* env,
        jobject obj __unused,
        jbyteArray data) {
    const int length = (*env)->GetArrayLength(env, data);
    unsigned char* image_buffer = (unsigned char*)malloc(sizeof(length));
    (*env)->GetByteArrayRegion(env, data, 0, length, (jbyte *)(image_buffer));
    size_t quality = jpeg_get_quality(image_buffer, length);
    free(image_buffer);
    return quality;
}

JNIEXPORT jint JNICALL
Java_com_larksuite_tool_image_JPEGTool_getJpegQualityByPath(
        JNIEnv * env,
        jobject obj __unused, /* this */
        jstring path) {
    const char* file_path = (*env)->GetStringUTFChars(env, path, 0);
    size_t quality = jpeg_get_quality_by_path(file_path);
    return quality;
}
