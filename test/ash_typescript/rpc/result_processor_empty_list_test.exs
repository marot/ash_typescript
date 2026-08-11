# SPDX-FileCopyrightText: 2025 ash_typescript contributors <https://github.com/ash-project/ash_typescript/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshTypescript.Rpc.ResultProcessorEmptyListTest.Summary do
  @moduledoc false
  use Ash.TypedStruct

  typed_struct do
    field(:total, :integer)
    field(:entries, {:array, :string})
    field(:options, :keyword, constraints: [fields: [priority: [type: :integer]]])
  end
end

defmodule AshTypescript.Rpc.ResultProcessorEmptyListTest.Anonymous do
  @moduledoc false
  defstruct entries: []
end

defmodule AshTypescript.Rpc.ResultProcessorEmptyListTest do
  use ExUnit.Case, async: true

  alias AshTypescript.Rpc.FieldProcessing.FieldProcessor
  alias AshTypescript.Rpc.ResultProcessor
  alias AshTypescript.Rpc.ResultProcessorEmptyListTest.Anonymous
  alias AshTypescript.Rpc.ResultProcessorEmptyListTest.Summary
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

    test "a struct whose module declares nothing keeps the object shape too" do
      result = ResultProcessor.normalize_value_for_json(%Anonymous{entries: []})

      assert result == %{entries: %{}}
    end
  end

  describe "empty values inside a returned struct" do
    test "an empty array field of a typed struct stays a list" do
      result = ResultProcessor.normalize_value_for_json(%Summary{total: 0, entries: []})

      assert result[:entries] == []
    end

    test "a populated array field of a typed struct is unchanged" do
      result = ResultProcessor.normalize_value_for_json(%Summary{total: 1, entries: ["a"]})

      assert result[:entries] == ["a"]
    end

    test "an empty keyword field of a typed struct stays an object" do
      result = ResultProcessor.normalize_value_for_json(%Summary{options: []})

      assert result[:options] == %{}
    end

    test "an empty array attribute of a resource struct stays a list" do
      result = ResultProcessor.normalize_value_for_json(%Todo{tags: []})

      assert result[:tags] == []
    end

    test "an empty keyword attribute of a resource struct stays an object" do
      result = ResultProcessor.normalize_value_for_json(%Todo{options: []})

      assert result[:options] == %{}
    end
  end

  describe "a :struct return with no instance_of constraint" do
    test "field selection falls back to the generic path instead of raising" do
      assert {[], [], [:total, :entries]} =
               FieldProcessor.process_fields_for_type(
                 {:ash_type, Ash.Type.Struct, []},
                 [:total, :entries],
                 []
               )
    end

    test "an empty field selection is still accepted" do
      assert {[], [], []} =
               FieldProcessor.process_fields_for_type({:ash_type, Ash.Type.Struct, []}, [], [])
    end
  end
end
