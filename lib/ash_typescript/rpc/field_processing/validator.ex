# SPDX-FileCopyrightText: 2025 ash_typescript contributors <https://github.com/ash-project/ash_typescript/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshTypescript.Rpc.FieldProcessing.Validator do
  @moduledoc """
  Validation functions for field processing, ensuring field selections are valid
  and properly structured.
  """

  alias AshTypescript.Rpc.FieldProcessing.Utilities

  @doc """
  Validates that nested fields are non-empty for fields that require field selection.

  Throws appropriate errors if validation fails.

  ## Parameters

  - `nested_fields` - The nested fields list to validate
  - `field_name` - The name of the field being validated
  - `path` - The current path in the field hierarchy
  - `error_type` - The type of field for error messages (default: "Relationship")
  """
  def validate_non_empty_fields(nested_fields, field_name, path, error_type \\ "Relationship") do
    if not is_list(nested_fields) do
      field_path = Utilities.build_field_path(path, field_name)

      throw(
        {:unsupported_field_combination, :relationship, field_name, nested_fields, field_path}
      )
    end

    if nested_fields == [] do
      field_path = Utilities.build_field_path(path, field_name)

      throw({:requires_field_selection, String.downcase(error_type), field_path})
    end
  end

  @doc """
  Validates that complex types have required fields provided.

  Ensures that fields parameter is both provided and non-empty for complex types
  that require field selection.

  ## Parameters

  - `fields_provided` - Boolean indicating if fields parameter was provided
  - `fields` - The fields list
  - `field_path` - The path to the field for error messages
  - `_type_description` - Description of the type (currently unused but kept for compatibility)
  """
  def validate_complex_type_fields(fields_provided, fields, field_path, _type_description) do
    if not fields_provided do
      throw({:requires_field_selection, :complex_type, field_path})
    end

    if fields == [] do
      throw({:requires_field_selection, :complex_type, field_path})
    end
  end

  @doc """
  Checks for duplicate field names in a field selection list.

  Throws an error if any field appears more than once.

  ## Parameters

  - `fields` - The list of fields to check
  - `path` - The current path in the field hierarchy for error messages
  - `resource` - Optional resource module for resolving field_names mappings
  """
  def check_for_duplicate_fields(fields, path, resource \\ nil) do
    field_names = Enum.flat_map(fields, &extract_field_names(&1, resource, path))

    duplicate_fields =
      field_names
      |> Enum.frequencies()
      |> Enum.filter(fn {_field, count} -> count > 1 end)
      |> Enum.map(fn {field, _count} -> field end)

    if !Enum.empty?(duplicate_fields) do
      duplicate_field = List.first(duplicate_fields)
      field_path = Utilities.build_field_path(path, duplicate_field)
      throw({:duplicate_field, duplicate_field, field_path})
    end
  end

  # Extracts and resolves field names from a field specification.
  #
  # Handles different field formats (atoms, strings, maps, tuples) and resolves
  # field_names mappings when a resource is provided.
  #
  # Returns a list of resolved field names (atoms).
  defp extract_field_names(field, resource, path) do
    case field do
      field_name when is_atom(field_name) ->
        [resolve_field_name(field_name, resource)]

      field_name when is_binary(field_name) ->
        try do
          field_atom = String.to_existing_atom(field_name)
          [resolve_field_name(field_atom, resource)]
        rescue
          _ ->
            throw({:invalid_field_type, field_name, path})
        end

      %{} = field_map ->
        Enum.map(Map.keys(field_map), &resolve_field_name(&1, resource))

      {field_name, _field_spec} ->
        [resolve_field_name(field_name, resource)]

      invalid_field ->
        throw({:invalid_field_type, invalid_field, path})
    end
  end

  # Resolves a field name using the resource's field_names mapping if available.
  #
  # Returns the original field name if a resource is provided, otherwise returns
  # the field name unchanged.
  defp resolve_field_name(field_name, nil), do: field_name

  defp resolve_field_name(field_name, resource) do
    AshTypescript.Resource.Info.get_original_field_name(resource, field_name)
  end
end
