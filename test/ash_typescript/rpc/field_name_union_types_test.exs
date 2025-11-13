# SPDX-FileCopyrightText: 2025 ash_typescript contributors <https://github.com/ash-project/ash_typescript/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshTypescript.Rpc.FieldNameUnionTypesTest do
  @moduledoc """
  Tests that generated TypeScript includes field name union types for compile-time validation.
  """
  use ExUnit.Case

  alias AshTypescript.Rpc.Codegen

  @moduletag :ash_typescript

  describe "field name union type generation" do
    test "generates union type with all field names for a resource" do
      {:ok, typescript} = Codegen.generate_typescript_types(:ash_typescript)

      # Should generate: type TodoFieldName = "id" | "title" | "description" | ...
      assert typescript =~ ~r/type TodoFieldName\s*=\s*[^;]*"id"[^;]*;/s
      assert typescript =~ ~r/type TodoFieldName\s*=.*"title"/s
      assert typescript =~ ~r/type TodoFieldName\s*=.*"completed"/s
    end

    test "includes calculations in field name union" do
      {:ok, typescript} = Codegen.generate_typescript_types(:ash_typescript)

      assert typescript =~ ~r/type TodoFieldName\s*=.*"isOverdue"/s
      assert typescript =~ ~r/type TodoFieldName\s*=.*"daysUntilDue"/s
    end

    test "includes aggregates in field name union" do
      {:ok, typescript} = Codegen.generate_typescript_types(:ash_typescript)

      assert typescript =~ ~r/type TodoFieldName\s*=.*"commentCount"/s
      assert typescript =~ ~r/type TodoFieldName\s*=.*"hasComments"/s
    end

    test "respects field name formatting and mapping" do
      {:ok, typescript} = Codegen.generate_typescript_types(:ash_typescript)

      assert typescript =~ ~r/type TodoFieldName\s*=.*"dueDate"/s
    end
  end
end
