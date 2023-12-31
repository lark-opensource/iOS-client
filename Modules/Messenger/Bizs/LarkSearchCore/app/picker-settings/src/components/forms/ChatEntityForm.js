import React, { memo, useContext, useEffect, useState } from "react";
import { Modal, Button } from "@arco-design/web-react";
import SelectComponent from "@/components/forms/SelectComponent";

const ChatEntityForm = memo(({ entity, onCancel, isShow, onSubmit }) => {
  const [tenant, setTenant] = useState(entity?.tenant ?? "inner");
  const [join, setJoin] = useState(entity?.join ?? "joined");
  const [owner, setOwner] = useState(entity?.owner ?? "all");
  const [shield, setShield] = useState(entity?.shield ?? "noShield");
  const [frozen, setFrozen] = useState(entity?.frozen ?? "noFrozened");
  const [crypto, setCrypto] = useState(entity?.crypto ?? "normal");
  const [publicType, setPublicType] = useState(entity?.publicType ?? "all");
  const [searchByUser, setSearchByUser] = useState(
    entity?.searchByUser ?? "all"
  );
  const [relationTag, setRelationTag] = useState(
    entity?.field?.relationTag ?? true
  );
  const [teamIdStr, setTeamIdStr] = useState(entity?.field?.teamIdStr ?? "");

  const formData = {
    element: [
      {
        type: "select",
        label: "内部外部群",
        options: [
          { value: "all", label: "全部群" },
          { value: "inner", label: "内部群" },
          { value: "outer", label: "外部群" },
        ],
        value: tenant,
        callback: setTenant,
      },
      {
        type: "select",
        label: "公开私有群",
        options: [
          { value: "all", label: "全部" },
          { value: "public", label: "仅公开群" },
          { value: "private", label: "仅私有群" },
        ],
        value: publicType,
        callback: setPublicType,
      },
      {
        type: "select",
        label: "是否加入群聊",
        options: [
          { value: "all", label: "全部" },
          { value: "joined", label: "加入的群" },
          { value: "unjoined", label: "未加入的群" },
        ],
        value: join,
        callback: setJoin,
      },
      {
        type: "select",
        label: "我管理的群组",
        options: [
          { value: "all", label: "全部" },
          { value: "ownered", label: "我管理的群组" },
        ],
        value: owner,
        callback: setOwner,
      },
      {
        type: "select",
        label: "密盾聊",
        options: [
          { value: "all", label: "全部" },
          { value: "shield", label: "密盾聊" },
          { value: "noShield", label: "非密盾聊" },
        ],
        value: shield,
        callback: setShield,
      },
      {
        type: "select",
        label: "密聊群",
        options: [
          { value: "all", label: "全部" },
          { value: "normal", label: "仅普通群" },
          { value: "crypto", label: "仅密聊群" },
        ],
        value: crypto,
        callback: setCrypto,
      },
      {
        type: "select",
        label: "冻结群",
        options: [
          { value: "all", label: "全部" },
          { value: "frozen", label: "冻结群" },
          { value: "noFrozened", label: "非冻结群" },
        ],
        value: frozen,
        callback: setFrozen,
      },
      {
        type: "select",
        label: "以人搜群",
        options: [
          { value: "all", label: "全部" },
          { value: "closeSearchByUser", label: "关闭以人搜群" },
        ],
        value: searchByUser,
        callback: setSearchByUser,
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
      join,
      owner,
      shield,
      frozen,
      crypto,
      publicType,
      searchByUser,
      field: {
        ...entity.field,
        relationTag,
        showEnterpriseMail: false,
      },
    };
    onSubmit && onSubmit(result);
  };

  return (
    <Modal
      style={{ width: "90vw" }}
      title="群组搜索配置"
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

export default ChatEntityForm;
