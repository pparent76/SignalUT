// Copyright 2026 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only

import { ipcRenderer } from 'electron';

type PickFileResultType =
  | Readonly<{
      canceled: true;
    }>
  | Readonly<{
      canceled: false;
      data: ArrayBuffer;
      name: string;
      lastModified: number;
      type: string;
    }>;

export const setupFileInputPicker = (): void => {
  document.addEventListener(
    'click',
    async event => {
      const target = event.target;
      if (!(target instanceof Element)) {
        return;
      }

      const input = target.closest<HTMLInputElement>('input[type="file"]');
      if (!input) {
        return;
      }

      event.preventDefault();
      event.stopImmediatePropagation();

      const result = (await ipcRenderer.invoke(
        'pick-file'
      )) as PickFileResultType;
      if (result.canceled) {
        return;
      }

      const file = new File([result.data], result.name, {
        lastModified: result.lastModified,
        type: result.type,
      });

      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(file);
      input.files = dataTransfer.files;

      input.dispatchEvent(new Event('input', { bubbles: true }));
      input.dispatchEvent(new Event('change', { bubbles: true }));
    },
    true
  );
};
