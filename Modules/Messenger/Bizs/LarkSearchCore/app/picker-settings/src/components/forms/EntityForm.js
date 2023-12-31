import React, { memo, useContext, useState } from "react";
import ChatterEntityForm from "@/components/forms/ChatterEntityForm";
import ChatEntityForm from "@/components/forms/ChatEntityForm";
import { ConfigContext } from "../../Context";

const EntityForm = memo(({ entity }) => {
  const context = useContext(ConfigContext);
  const { state, dispatch } = context;

  const handleSubmit = (entity) => {
    dispatch({
      event: "saveEditEntity",
      payload: {
        entity: entity,
      },
    });
  };

  const handleCancel = () => {
    dispatch({
      event: "cancel_edit_entity",
    });
  };

  if (entity?.entity?.type === undefined) return null;
  switch (entity.entity.type) {
    case "chatter":
      return (
        <ChatterEntityForm
          entity={entity.entity}
          onCancel={handleCancel}
          onSubmit={handleSubmit}
          isShow={state?.editEntity !== null}
        />
      );
    case "chat":
      return (
        <ChatEntityForm
          entity={entity.entity}
          onCancel={handleCancel}
          onSubmit={handleSubmit}
          isShow={state?.editEntity !== null}
        />
      );
    default:
      return null;
  }
});

export default EntityForm;
