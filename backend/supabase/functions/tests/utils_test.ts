import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { validateUUID, truncateText, formatTimestamp } from "../_shared/utils.ts";

Deno.test("validateUUID returns true for valid UUID", () => {
  const validUUID = "550e8400-e29b-41d4-a716-446655440000";
  assertEquals(validateUUID(validUUID), true);
});

Deno.test("validateUUID returns false for invalid UUID", () => {
  const invalidUUID = "not-a-valid-uuid";
  assertEquals(validateUUID(invalidUUID), false);
});

Deno.test("validateUUID returns false for empty string", () => {
  assertEquals(validateUUID(""), false);
});

Deno.test("truncateText returns original text if under limit", () => {
  const text = "Hello";
  assertEquals(truncateText(text, 10), "Hello");
});

Deno.test("truncateText truncates long text with ellipsis", () => {
  const text = "This is a very long message";
  assertEquals(truncateText(text, 10), "This is...");
});

Deno.test("formatTimestamp returns ISO string", () => {
  const date = new Date("2024-01-15T12:00:00Z");
  assertEquals(formatTimestamp(date), "2024-01-15T12:00:00.000Z");
});
