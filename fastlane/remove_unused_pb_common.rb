module Fastlane
  class FastFile
    def _revert_remove_unused_pb(options)
      options["REVERT_OLD_REVMOE_RESULE"] = true
      _remove_unused_pb(options)
    end

    def _remove_unused_pb(options)
      # 删除无用pb message（文档：https://bytedance.feishu.cn/wiki/wikcnSevDX5Izu7OSlfmAmVxrle）
      return if ENV['BITS_PIPELINE_PACKAGE']
      
      append="--revert-before-remove"
      if options['REVERT_OLD_REVMOE_RESULE']
        append="-r"
      end

      pods_dir = "../Pods"
      if options["CUSTOM_PROJECT_PODS"]
        pods_dir = options["CUSTOM_PROJECT_PODS"]
      end

      project_dir=options['REMOVE_PB_PROEJCT_DIR'] || ".."

      sh "
        set -e
        set -x

        REMOVE_PB_URL=http://tosv.byted.org/obj/ee-infra-ios/tools/RemoveUnusedPB/2023-07-20.tar.xz
        OUTPUT_NAME=RemoveUnusedPB.tar.xz

        function download_via_curl() {
          curl -s --show-error --retry 5 --retry-delay 0 ${REMOVE_PB_URL} --output ${OUTPUT_NAME}
        }

        if which wget >/dev/null ; then
          wget -q ${REMOVE_PB_URL} -O ${OUTPUT_NAME} || download_via_curl
        else
          download_via_curl
        fi

        tar xf ${OUTPUT_NAME}
        rm ${OUTPUT_NAME}

        chmod +x ./RemoveUnusedPB
        codesign --force --deep --sign - ./RemoveUnusedPB
        
        log_dir=${GYM_BUILDLOG_PATH:-Logs}
        mkdir -p $log_dir
        
        function remove_unused_PB() {
          ./RemoveUnusedPB -p #{project_dir}/ \
          -pb #{pods_dir}/RustPB/src/protobuf \
          -pb #{pods_dir}/ServerPB/src/pb_swift \
          -o ${log_dir} \
          -k RustPB \
          -k ServerPB \
          -k has \
          -k clear \
          #{append}
        }
        ./RemoveUnusedPB -v
        remove_unused_PB || remove_unused_PB || remove_unused_PB || (exit -10087 && echo \"清理无用PB失败，请重试任务。\")
      "
    end
  end
end