# SPDX-FileCopyrightText: 2025 ash_typescript contributors <https://github.com/ash-project/ash_typescript/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshTypescript.Codegen.TypedStructAttributeTest.Availability do
  @moduledoc false
  use Ash.Resource,
    domain: nil,
    validate_domain_inclusion?: false,
    extensions: [AshTypescript.Resource]

  typescript do
    type_name "TypedStructAvailability"
  end

  attributes do
    uuid_primary_key(:id)

    attribute :spans, {:array, AshTypescript.Test.TaskStats} do
      public?(true)
    end

    attribute :summary, AshTypescript.Test.TaskStats do
      public?(true)
    end
  end
end

defmodule AshTypescript.Codegen.TypedStructAttributeTest do
  use ExUnit.Case, async: true

  alias AshTypescript.Codegen.ResourceSchemas
  alias AshTypescript.Codegen.TypedStructAttributeTest.Availability
  alias AshTypescript.Rpc.FieldProcessing.FieldProcessor

  describe "an attribute typed as an array of typed structs" do
    test "is served whole by field processing" do
      assert {[:spans], [], [:spans]} =
               FieldProcessor.process_resource_fields(Availability, [:spans], [])
    end

    test "can be named in the generated field name union" do
      union = ResourceSchemas.generate_field_name_union_type(Availability)

      assert union =~ "\"spans\""
    end

    test "is given a type in the generated resource schema" do
      schema = ResourceSchemas.generate_unified_resource_schema(Availability, [Availability])

      assert schema =~ "spans: Array<{"
      assert schema =~ "__primitiveFields: \"id\" | \"spans\";"
    end
  end

  describe "an attribute typed as a single typed struct" do
    test "asks field processing for a nested selection" do
      assert {:requires_field_selection, :typed_struct, _} =
               catch_throw(FieldProcessor.process_resource_fields(Availability, [:summary], []))
    end

    test "stays out of the field name union" do
      union = ResourceSchemas.generate_field_name_union_type(Availability)

      refute union =~ "\"summary\""
    end
  end
end
