// SPDX-FileCopyrightText: 2025 ash_typescript contributors <https://github.com/ash-project/ash_typescript/graphs.contributors>
//
// SPDX-License-Identifier: MIT

// Field Name Union Type Validation Tests
// Verifies that field name union types catch invalid field names at compile time

import { listTodos, getTodo } from "../generated";

// Test: Invalid field name typo
export const fieldNameTypo = await listTodos({
  fields: [
    "id",
    "title",
    // @ts-expect-error - "ttle" is a typo and should not be valid
    "ttle",
  ],
});

// Test: Completely invalid field name
export const invalidFieldName = await getTodo({
  input: {},
  fields: [
    "id",
    "title",
    // @ts-expect-error - "nonExistentField" should not be valid
    "nonExistentField",
    // @ts-expect-error - "fakeAttribute" should not be valid
    "fakeAttribute",
  ],
});

// Test: Invalid calculation field name
export const invalidCalculationField = await getTodo({
  input: {},
  fields: [
    "id",
    "isOverdue",
    // @ts-expect-error - "isNotOverdue" should not be valid
    "isNotOverdue",
  ],
});

// Test: Invalid aggregate field name
export const invalidAggregateField = await getTodo({
  input: {},
  fields: [
    "id",
    "commentCount",
    // @ts-expect-error - "commentTotal" should not be valid
    "commentTotal",
  ],
});
