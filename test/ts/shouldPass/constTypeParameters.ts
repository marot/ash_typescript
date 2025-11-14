// SPDX-FileCopyrightText: 2025 ash_typescript contributors <https://github.com/ash-project/ash_typescript/graphs.contributors>
//
// SPDX-License-Identifier: MIT

// Const Type Parameters Test - shouldPass
// Tests that verify TypeScript 5.0+ const type parameters work correctly
// These tests demonstrate that array literals are properly inferred as tuples
// WITHOUT requiring 'as const' assertions from users

import { getTodo, listTodos, createTodo, updateTodo } from "../generated";

// ============================================================================
// READ OPERATIONS - Array literals should be inferred as readonly tuples
// ============================================================================

// Test 1: Simple field selection without 'as const'
export const simpleReadTest = await getTodo({
  input: { id: "123" },
  fields: ["id", "title", "completed"], // No 'as const' needed!
});

// Verify type inference - these properties should be accessible
if (simpleReadTest.success && simpleReadTest.data) {
  const id: string = simpleReadTest.data.id;
  const title: string = simpleReadTest.data.title;
  const completed: boolean | null = simpleReadTest.data.completed;
}

// Test 2: List operation with nested fields (no 'as const')
export const listReadTest = await listTodos({
  input: {},
  fields: [
    "id",
    "title",
    "status",
    {
      user: ["id", "email"], // Nested fields also work without 'as const'
    },
  ],
});

if (listReadTest.success) {
  const firstTodo = listReadTest.data[0];
  if (firstTodo) {
    const id: string = firstTodo.id;
    const title: string = firstTodo.title;
    const status: "pending" | "ongoing" | "finished" | "cancelled" | null =
      firstTodo.status;
    const userId: string = firstTodo.user.id;
    const userEmail: string = firstTodo.user.email;
  }
}

// ============================================================================
// MUTATION OPERATIONS - Optional fields also benefit from const
// ============================================================================

// Test 3: Create operation (fields optional)
export const createTest = await createTodo({
  input: { title: "Test", userId: "user-123" },
  fields: ["id", "title", "createdAt"],
});

if (createTest.success) {
  const id: string = createTest.data.id;
  const title: string = createTest.data.title;
  const createdAt: string = createTest.data.createdAt;
}

// Test 4: Update operation (fields optional)
export const updateTest = await updateTodo({
  primaryKey: "123",
  input: { title: "Updated" },
  fields: ["id", "title", "completed"],
});

if (updateTest.success) {
  const id: string = updateTest.data.id;
  const title: string = updateTest.data.title;
  const completed: boolean | null = updateTest.data.completed;
}

// ============================================================================
// BACKWARDS COMPATIBILITY - 'as const' should still work
// ============================================================================

// Test 5: Verify 'as const' still works for users who want to use it
export const withAsConstTest = await getTodo({
  input: { id: "123" },
  fields: ["id", "title"] as const, // Explicit 'as const' should still work
});

if (withAsConstTest.success && withAsConstTest.data) {
  const id: string = withAsConstTest.data.id;
  const title: string = withAsConstTest.data.title;
}

console.log("✅ All const type parameter tests passed!");
