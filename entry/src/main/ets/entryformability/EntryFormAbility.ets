import FormPreference from '../formcommon/utils/FormPreference';
import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    /**
     * This is the automatically generated code for the logic of card interactions.
     * Used to persist formId and formName.
     */
    FormPreference.persistForm(want, this.context)


    // Called to return a FormBindingData object.
    let formData = '';
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
  }

  onUpdateForm(formId: string) {
    // RDB卡片更新链路已移除(元服务不支持relationalStore,且原DB无种子数据)
    // Called to notify the form provider to update a specified form.
  }

  onChangeFormVisibility(newStatus: Record<string, number>) {
    // Called when the form provider receives form events from the system.
  }

  onFormEvent(formId: string, message: string) {
    /**
     * This is the automatically generated code for the logic of card interactions.
     * Used to http update form through message event.
     */
    // RDB卡片更新链路已移除(元服务不支持relationalStore,且原DB无种子数据)
    // Called when a specified message event defined by the form provider is triggered.
  }

  onRemoveForm(formId: string) {
    /**
     * This is the automatically generated code for the logic of card interactions.
     * Remove formId and formName from persistence.
     */
    FormPreference.removePersistentForm(formId, this.context);


    // Called to notify the form provider that a specified form has been destroyed.
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    return formInfo.FormState.READY;
  }
};