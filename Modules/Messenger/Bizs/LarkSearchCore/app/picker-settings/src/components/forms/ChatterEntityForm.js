import React, { memo, useContext, useEffect, useState } from "react";
import { Modal, Button } from "@arco-design/web-react";
import SelectComponent from "@/components/forms/SelectComponent";

const ChatterEntityForm = memo(({ entity, onSubmit, onCancel, isShow }) => {
  const [tenant, setTenant] = useState(entity?.tenant || "inner");
  const [talk, setTalk] = useState(entity?.talk || "talked");
  const [resign, setResign] = useState(entity?.resign || "unresigned");
  const [externalFriend, setExternalFriend] = useState(
    entity?.externalFriend || "all"
  );

  const formData = {
    element: [
      {
        type: "select",
        label: "租户类型",
        options: [
          { value: "all", label: "全部租户" },
          { value: "inner", label: "内部租户" },
          // { value: "outer", label: "外部" },
        ],
        value: tenant,
        callback: setTenant,
      },
      {
        type: "select",
        label: "聊天类型",
        options: [
          { value: "all", label: "聊过&未聊过" },
          { value: "talked", label: "已聊天" },
          { value: "untalked", label: "未聊天" },
        ],
        value: talk,
        callback: setTalk,
      },
      {
        type: "select",
        label: "在职状态",
        options: [
          { value: "all", label: "全部" },
          { value: "resigned", label: "已离职" },
          { value: "unresigned", label: "在职" },
        ],
        value: resign,
        callback: setResign,
      },
      {
        type: "select",
        label: "是否属于外部好友",
        options: [
          { value: "all", label: "全部" },
          { value: "noExternalFriend", label: "不属于外部好友" },
        ],
        value: externalFriend,
        callback: setExternalFriend,
      },
    ],
  };

  const handleCancelEntity = () => {
    onCancel && onCancel();
  };

  const handleSubmit = () => {
    const result = {
      ...entity,
      tenant,
      talk,
      resign,
      externalFriend,
    };
    onSubmit && onSubmit(result);
  };

  return (
    <Modal
      style={{ width: "90vw" }}
      title="人员搜索配置"
      visible={isShow}
      onOk={handleSubmit}
      onCancel={handleCancelEntity}
      autoFocus={false}
      focusLock={true}
    >
      <form autoComplete="off">
        <div className="grid grid-cols-2 gap-x-2 gap-y-1">
          {formData.element.map((item, index) => {
            return <SelectComponent item={item} key={index} />;
          })}
        </div>
      </form>
    </Modal>
  );
});

export default ChatterEntityForm;
