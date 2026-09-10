import assert from "node:assert/strict";
import test from "node:test";

import {onboardingPayload, optionalEmail} from "../src/validation.js";

const valid = {
  businessName: "Example Store",
  businessAddress: "Main Road, Amravati",
  businessType: "soleProprietorship",
  businessPhone: "+919876543210",
  businessEmail: "",
  gstNumber: "27ABCDE1234F1Z5",
  city: "Amravati",
  state: "Maharashtra",
  country: "India",
  postalCode: "444601",
};

test("onboarding accepts an optional blank email", () => {
  assert.equal(onboardingPayload(valid).businessEmail, "");
});

test("onboarding trims all user-entered strings", () => {
  const payload = onboardingPayload({...valid, city: "  Amravati  "});
  assert.equal(payload.city, "Amravati");
});

test("invalid non-empty email is rejected", () => {
  assert.throws(() => optionalEmail({businessEmail: "invalid"}));
});

test("unknown business type is rejected", () => {
  assert.throws(() => onboardingPayload({...valid, businessType: "unknown"}));
});
