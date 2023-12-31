package com.larksuite.tool.image;

public class JPEGTool {
    static {
        // Used to load the 'native-lib' library on application startup.
        System.loadLibrary("JPEG-LIB");
    }

    public static native boolean isJPEG(byte[] data);

    public static native int getJpegQuality(byte[] data);

    public static native int getJpegQualityByPath(String path);
}
