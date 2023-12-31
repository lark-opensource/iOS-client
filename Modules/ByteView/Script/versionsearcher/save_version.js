/**
  * @param params 调用参数，HTTP 请求下为请求体
  * @param context 调用上下文
  *
  * @return 函数的返回数据，HTTP 场景下会作为 Response Body
  *
  * 完整信息可参考：
  * https://larkcloud.bytedance.net/docs/cloud-function/basic.html
  */

const db = larkcloud.db.table('sdk_version')
module.exports = async function(params, context) {
  console.log(context)
  let os = params.os
  
  let array = params.array
  for(let i in array){
    var version = array[i]
    let item = await db.where({"os":os,"lark_version": version["lark_version"]}).findOne()
    if(item){
      for (var key in version) {
        item[key] = version[key]
      }
      await db.save(item)
    }else{
      version["os"] = os
      let new_item = await db.create(version)
      await db.save(new_item)
    }
  }
  return params
}