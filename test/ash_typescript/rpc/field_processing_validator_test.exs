# SPDX-FileCopyrightText: 2025 ash_typescript contributors <https://github.com/ash-project/ash_typescript/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshTypescript.Rpc.FieldProcessingValidatorTest do
  @moduledoc """
  Tests for field validation with field_names mappings.

  This test module specifically targets the bug in check_for_duplicate_fields/2
  where the validator fails to resolve field_names mappings before validating
  field existence.
  """
  use ExUnit.Case, async: true

  alias AshTypescript.Rpc
  alias AshTypescript.Test.Task

  setup do
    conn = %Plug.Conn{
      assigns: %{
        ash_actor: nil,
        ash_tenant: nil
      }
    }

    {:ok, conn: conn}
  end

  describe "field validation with field_names mappings" do
    test "validates mapped field names correctly", %{conn: conn} do
      # Task resource has: archived?: :is_archived mapping
      # This test sends the mapped TypeScript name "isArchived"
      # which should be accepted by the validator

      _task =
        Task
        |> Ash.Changeset.for_create(:create, %{title: "Test Task"})
        |> Ash.Changeset.force_change_attribute(:archived?, true)
        |> Ash.create!()

      # Request with mapped field name
      result =
        Rpc.run_action(:ash_typescript, conn, %{
          "action" => "list_tasks",
          "resource" => "Task",
          "fields" => ["isArchived"]
        })

      # This should succeed - the validator should resolve isArchived -> archived?
      assert %{"success" => true, "data" => [found_task]} = result
      assert found_task["isArchived"] == true
    end

    test "accepts string representation of mapped field name", %{conn: conn} do
      # This test specifically targets the bug where String.to_existing_atom
      # fails because the atom for the intermediate form doesn't exist

      _task =
        Task
        |> Ash.Changeset.for_create(:create, %{title: "String Test"})
        |> Ash.create!()

      # The validator will receive "isArchived" as a string
      # It will try String.to_existing_atom("is_archived") which should fail
      # because only :archived? atom exists (not :is_archived)
      result =
        Rpc.run_action(:ash_typescript, conn, %{
          "action" => "list_tasks",
          "resource" => "Task",
          "fields" => ["isArchived"]
        })

      # Currently this FAILS with {:invalid_field_type, "is_archived", []}
      # After fix, this should succeed
      assert %{"success" => true, "data" => [found_task]} = result
      assert Map.has_key?(found_task, "isArchived")
    end

    test "detects duplicate fields after resolving mappings", %{conn: conn} do
      # This test verifies that duplicate detection works correctly
      # when the same field is referenced multiple times

      _task =
        Task
        |> Ash.Changeset.for_create(:create, %{title: "Duplicate Test"})
        |> Ash.create!()

      # Request the same mapped field twice
      result =
        Rpc.run_action(:ash_typescript, conn, %{
          "action" => "list_tasks",
          "resource" => "Task",
          "fields" => ["isArchived", "isArchived"]
        })

      # This should fail with duplicate field error
      # After the bug is fixed, both field references should resolve to :archived?
      # and be detected as duplicates
      assert %{"success" => false, "errors" => errors} = result
      assert is_list(errors)
      assert length(errors) > 0

      # Verify it's a duplicate field error
      error = List.first(errors)
      assert Map.has_key?(error, "message")
      assert error["message"] =~ "multiple times"
    end

    test "detects duplicates when mixing original and mapped names", %{conn: conn} do
      # This test verifies duplicate detection when using both
      # the original Elixir name and the mapped TypeScript name

      _task =
        Task
        |> Ash.Changeset.for_create(:create, %{title: "Mixed Names Test"})
        |> Ash.create!()

      # Request both "archived?" (original) and "isArchived" (mapped)
      # These refer to the same field and should be detected as duplicates
      result =
        Rpc.run_action(:ash_typescript, conn, %{
          "action" => "list_tasks",
          "resource" => "Task",
          "fields" => ["archived?", "isArchived"]
        })

      # This should fail with duplicate field error
      assert %{"success" => false, "errors" => errors} = result
      assert is_list(errors)
      assert length(errors) > 0
    end

    test "works with multiple mapped and unmapped fields", %{conn: conn} do
      # Test that both mapped and unmapped fields work together

      _task =
        Task
        |> Ash.Changeset.for_create(:create, %{title: "Mixed Fields Test"})
        |> Ash.Changeset.force_change_attribute(:archived?, false)
        |> Ash.create!()

      # Request mix of mapped (isArchived) and unmapped (title, completed) fields
      result =
        Rpc.run_action(:ash_typescript, conn, %{
          "action" => "list_tasks",
          "resource" => "Task",
          "fields" => ["title", "completed", "isArchived"]
        })

      assert %{"success" => true, "data" => [found_task]} = result
      assert found_task["title"] == "Mixed Fields Test"
      assert found_task["completed"] == false
      assert found_task["isArchived"] == false
    end
  end
end
