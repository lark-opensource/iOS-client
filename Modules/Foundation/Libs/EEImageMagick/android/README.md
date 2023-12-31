打包aar上传maven步骤：

1. 升级版本号：build./gradle{LIB_IMAGE_VERSION}
2. 当前目录运行：  $./gradlew :image-library:uploadArchives

返回400：
当前版本已存，升级版本号再重新上传
