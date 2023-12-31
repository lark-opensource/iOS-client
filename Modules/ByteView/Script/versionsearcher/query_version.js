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
  let action = params.action
  switch(action.toLowerCase()){
    case "getversion":
      let version_list = await getVersion()
      return version_list
    case "gettable":
      let table = await getTable(params.os,params.version)
      return table.sort(sortVersion)
  }

}

async function getTable(os,version){
  let reg = new RegExp("^"+version)
  let items = await db.where({os:os,lark_version:reg}).find()
  console.log(items)
  return items
}

async function getVersion(){
  let items = await db.where({os:"ios"}).projection({lark_version:1,_id:0}).find()
  var array = []
  for(let i in items){
    let item = items[i].lark_version
    let versionArray = item.split(".")
    let version = versionArray[0] + "." + versionArray[1]
    if(array.indexOf(version)==-1)
      array.push(version)
  }
  console.log(array)
  return array
}

function getNumberVersion(version){
  var array = version.split(".")
  var max = Number(array[0])
  var middle = Number(array[1])
  var littleString = array[2]
  var beta = 0
  if(littleString.search("beta")!=-1)
    beta = Number(littleString.split("beta")[1])
  if(littleString.search("-")!=-1)
    littleString = littleString.split("-")[0]
  if(littleString.search("_")!=-1) 
    littleString = littleString.split("_")[0]
  littleString = littleString.trim()
  var little = Number(littleString)
  return (((max*100+middle)*100+little)*100+beta)
}

function sortVersion(a,b){
  return getNumberVersion(b.lark_version) - getNumberVersion(a.lark_version)
}