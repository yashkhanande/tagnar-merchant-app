import {HttpsError} from "firebase-functions/v2/https";

export const businessTypes = new Set([
  "soleProprietorship",
  "partnership",
  "corporation",
  "llc",
  "cooperative",
  "nonprofit",
]);

export function requireString(data, key, min, max) {
  const value = data?.[key];
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${key} must be a string.`);
  }
  const normalized = value.trim();
  if (normalized.length < min || normalized.length > max) {
    throw new HttpsError(
        "invalid-argument",
        `${key} must contain ${min}–${max} characters.`,
    );
  }
  return normalized;
}

export function optionalEmail(data, key = "businessEmail") {
  const value = requireString(data, key, 0, 254);
  if (value && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
    throw new HttpsError("invalid-argument", "Enter a valid business email.");
  }
  return value;
}

export function onboardingPayload(data) {
  const businessType = requireString(data, "businessType", 1, 40);
  if (!businessTypes.has(businessType)) {
    throw new HttpsError("invalid-argument", "Select a valid business type.");
  }
  return {
    businessName: requireString(data, "businessName", 2, 200),
    businessAddress: requireString(data, "businessAddress", 5, 500),
    businessType,
    businessPhone: requireString(data, "businessPhone", 8, 20),
    businessEmail: optionalEmail(data),
    gstNumber: requireString(data, "gstNumber", 2, 30),
    city: requireString(data, "city", 2, 100),
    state: requireString(data, "state", 2, 100),
    country: requireString(data, "country", 2, 100),
    postalCode: requireString(data, "postalCode", 3, 20),
    onboardingCompleted: true,
  };
}
