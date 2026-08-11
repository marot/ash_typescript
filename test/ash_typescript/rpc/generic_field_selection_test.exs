# SPDX-FileCopyrightText: 2025 ash_typescript contributors <https://github.com/ash-project/ash_typescript/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshTypescript.Rpc.GenericFieldSelectionTest do
  use ExUnit.Case, async: true

  alias AshTypescript.Rpc.ErrorBuilder
  alias AshTypescript.Rpc.FieldProcessing.FieldProcessor
  alias AshTypescript.Rpc.RequestedFieldsProcessor
  alias AshTypescript.Rpc.ResultProcessor
  alias AshTypescript.Test.Todo

  @generic_return {:ash_type, Ash.Type.Struct, []}

  defp requested(field_name) do
    [field] = RequestedFieldsProcessor.atomize_requested_fields([field_name])
    field
  end

  describe "a requested field name that names nothing" do
    test "is reported as an unknown field on the generic path" do
      field = requested("neverDeclaredGenericFieldXyz")

      assert is_binary(field),
             "the fixture only holds if no atom exists for the name"

      assert {:unknown_field, ^field, "generic", "neverDeclaredGenericFieldXyz"} =
               catch_throw(FieldProcessor.process_fields_for_type(@generic_return, [field], []))
    end

    test "is reported as an unknown field on the resource path" do
      field = requested("neverDeclaredResourceFieldXyz")

      assert {:error, {:unknown_field, _field, Todo, "neverDeclaredResourceFieldXyz"}} =
               RequestedFieldsProcessor.process(Todo, :read, [field])
    end

    test "is reported as an unknown field on the map path" do
      field = requested("neverDeclaredMapFieldXyz")

      assert {:unknown_field, _field, "map", "neverDeclaredMapFieldXyz"} =
               catch_throw(
                 FieldProcessor.process_map_fields(
                   [fields: [total: [type: :integer]]],
                   [field],
                   []
                 )
               )
    end

    test "reaches the client with the same error shape on both paths" do
      generic =
        catch_throw(
          FieldProcessor.process_fields_for_type(
            @generic_return,
            [requested("neverDeclaredGenericShapeXyz")],
            []
          )
        )
        |> ErrorBuilder.build_error_response()

      {:error, resource_error} =
        RequestedFieldsProcessor.process(Todo, :read, [requested("neverDeclaredResourceShapeXyz")])

      resource = ErrorBuilder.build_error_response(resource_error)

      assert generic.type == resource.type
      assert generic.type == "unknown_field"
      assert Map.keys(generic) == Map.keys(resource)
      assert generic.field_path == "neverDeclaredGenericShapeXyz"
      assert Map.has_key?(generic.details, :field)
      assert Map.has_key?(generic.details, :suggestion)
    end

    test "a nested selection under an unknown name is reported the same way" do
      field = requested("neverDeclaredNestedFieldXyz")

      assert {:unknown_field, _field, "generic", "neverDeclaredNestedFieldXyz"} =
               catch_throw(
                 FieldProcessor.process_fields_for_type(
                   @generic_return,
                   [%{field => [:id]}],
                   []
                 )
               )
    end
  end

  describe "fields a struct keeps for itself" do
    test "are not answered for when there is no resource to select against" do
      todo = %Todo{id: "todo-1", title: "Ship it"}

      result = ResultProcessor.process(todo, [:id, :title, :__meta__, :aggregates], nil)

      assert result == %{id: "todo-1", title: "Ship it"}
    end

    test "are not answered for under a nested selection either" do
      todo = %Todo{id: "todo-1"}

      result = ResultProcessor.process(todo, [:id, {:__meta__, [:source]}], nil)

      assert result == %{id: "todo-1"}
    end

    test "are left out of a struct handed back whole" do
      normalized = ResultProcessor.normalize_value_for_json(%Todo{id: "todo-1"})

      refute Map.has_key?(normalized, :__meta__)
      assert normalized[:id] == "todo-1"
    end

    test "a public attribute is still answered for" do
      todo = %Todo{id: "todo-1", tags: ["urgent"]}

      assert ResultProcessor.process(todo, [:tags], nil) == %{tags: ["urgent"]}
    end

    test "a selection against a named resource is unchanged" do
      todo = %Todo{id: "todo-1", title: "Ship it"}

      assert ResultProcessor.process(todo, [:id, :title], Todo) == %{
               id: "todo-1",
               title: "Ship it"
             }
    end
  end
end
