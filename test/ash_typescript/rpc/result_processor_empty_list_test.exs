# SPDX-FileCopyrightText: 2025 ash_typescript contributors <https://github.com/ash-project/ash_typescript/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshTypescript.Rpc.ResultProcessorEmptyListTest do
  use ExUnit.Case, async: true

  alias AshTypescript.Rpc.ResultProcessor
  alias AshTypescript.Test.Todo

  describe "empty values in list-typed fields" do
    test "an empty array attribute stays a list" do
      data = %{id: "todo-1", tags: []}

      result = ResultProcessor.process(data, [:id, :tags], Todo)

      assert result == %{id: "todo-1", tags: []}
    end

    test "a populated array attribute is unchanged" do
      data = %{id: "todo-1", tags: ["urgent", "work"]}

      result = ResultProcessor.process(data, [:id, :tags], Todo)

      assert result == %{id: "todo-1", tags: ["urgent", "work"]}
    end

    test "an empty array of embedded resources stays a list" do
      data = %{id: "todo-1", metadata_history: []}

      result = ResultProcessor.process(data, [:id, :metadata_history], Todo)

      assert result == %{id: "todo-1", metadata_history: []}
    end

    test "an empty list aggregate stays a list" do
      data = %{id: "todo-1", comment_authors: []}

      result = ResultProcessor.process(data, [:id, :comment_authors], Todo)

      assert result == %{id: "todo-1", comment_authors: []}
    end

    test "an empty relationship stays a list" do
      data = %{id: "todo-1", comments: []}

      result = ResultProcessor.process(data, [:id, {:comments, [:id]}], Todo)

      assert result == %{id: "todo-1", comments: []}
    end

    test "a top-level empty result stays a list" do
      assert ResultProcessor.process([], [:id, :tags], Todo) == []
    end
  end

  describe "empty values in object-typed fields" do
    test "an empty keyword attribute stays an object" do
      data = %{id: "todo-1", options: []}

      result = ResultProcessor.process(data, [:id, :options], Todo)

      assert result == %{id: "todo-1", options: %{}}
    end

    test "a populated keyword attribute is unchanged" do
      data = %{id: "todo-1", options: [priority: 7, category: "work", notify: true]}

      result = ResultProcessor.process(data, [:id, :options], Todo)

      assert result == %{
               id: "todo-1",
               options: %{"priority" => 7, "category" => "work", "notify" => true}
             }
    end

    test "an empty map attribute stays an object" do
      data = %{id: "todo-1", custom_data: %{}}

      result = ResultProcessor.process(data, [:id, :custom_data], Todo)

      assert result == %{id: "todo-1", custom_data: %{}}
    end

    test "a populated map attribute is unchanged" do
      data = %{id: "todo-1", custom_data: %{"a" => 1}}

      result = ResultProcessor.process(data, [:id, :custom_data], Todo)

      assert result == %{id: "todo-1", custom_data: %{"a" => 1}}
    end
  end

  describe "fields without declared type information" do
    test "an empty keyword result keeps its object shape" do
      assert ResultProcessor.normalize_value_for_json([]) == %{}
    end
  end
end
