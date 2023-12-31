import React, { useContext } from "react";
import NavBarComponent from "@/components/NavBarComponent";
import { ConfigContext } from "../Context";
import { IconDelete, IconAdd } from "@arco-design/mobile-react/esm/icon";
import { getEntityName } from "@/utils/utils";
import EntityPicker from "@/components/EntityPicker";
import EntityForm from "@/components/forms/EntityForm";

export default function SearchConfigListPage(props) {
  const context = useContext(ConfigContext);
  const { state, dispatch } = context;
  const [visible, setVisible] = React.useState(false);
  const { entities } = state.config.searchConfig;

  const handleOpenPicker = () => {
    setVisible(true);
  };

  const handleDeleteEntity = (entity, index) => {
    dispatch({
      event: "delete_entity",
      payload: {
        entity: entity,
        index: index,
      },
    });
  };

  const handleEditEntity = (entity, index) => {
    dispatch({
      event: "edit_entity",
      payload: {
        entity: entity,
        index: index,
      },
    });
  };

  const handleAddEntity = (type, index) => {
    dispatch({
      event: "add_entity",
      payload: {
        type: type,
      },
    });
  };

  // UI
  const AddEntityButton = ({ onClick }) => {
    const handleClick = () => {
      onClick();
    };
    return (
      <div
        className="w-4 h-4 flex justify-center items-center"
        onClick={handleClick}
      >
        <IconAdd />
      </div>
    );
  };

  const SearchEntityList = (props) => {
    return props.entities === undefined ? (
      <div />
    ) : (
      props.entities.map((entity, i) => {
        return (
          <div
            className="flex flex-row items-center"
            key={i + entity.type}
            style={{ margin: "16px" }}
          >
            <div
              className="flex flex-col space-y-1 grow"
              onClick={(e) => handleEditEntity(entity, i)}
            >
              <div
                className="basis-4"
                style={{
                  fontSize: 18,
                  fontWeight: "bold",
                  lineHeight: "18px",
                  marginBottom: -17,
                  paddingTop: 16,
                }}
              >
                {getEntityName(entity)}
              </div>
              <div className="text-[12px] line-clamp-5 w-20 break-words">
                {JSON.stringify(entity)}
              </div>
            </div>
            <div
              style={{ padding: "10px" }}
              onClick={(e) => handleDeleteEntity(entity, i)}
            >
              <IconDelete style={{ fontSize: "22px" }} />
            </div>
          </div>
        );
      })
    );
  };

  return (
    <div className="main-div">
      <NavBarComponent
        title={"搜索配置"}
        hasBack={true}
        right={<AddEntityButton onClick={handleOpenPicker} />}
      />
      <div>
        <SearchEntityList entities={entities.chatters} />
        <SearchEntityList entities={entities.chats} />
        <SearchEntityList entities={entities.userGroups} />
        <SearchEntityList entities={entities.dynamicUserGroups} />
        <SearchEntityList entities={entities.docs} />
        <SearchEntityList entities={entities.wikis} />
        <SearchEntityList entities={entities.wikiSpaces} />
      </div>
      <div>
        <EntityForm entity={state.editEntity} />
      </div>
      <EntityPicker
        visible={visible}
        onHide={() => {
          setVisible(false);
        }}
        onSure={handleAddEntity}
      />
    </div>
  );
}
