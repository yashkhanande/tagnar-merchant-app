import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tagnar_merchant/models/merchant.dart';

class MerchantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Merchant?> getMerchant(String uid) async {
    final doc = await _firestore.collection("merchants_new").doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return Merchant.fromMap(doc.data()!);
  }

  List<String> getMissingFields(Merchant merchant) {
    final List<String> missingFields = [];

    if (merchant.businessName.trim().isEmpty) {
      missingFields.add("Business Name");
    }

    if (merchant.businessAddress.trim().isEmpty) {
      missingFields.add("Business Address");
    }

    if (merchant.businessType == BusinessType.none) {
      missingFields.add("Business Type");
    }

    if (merchant.businessPhone.trim().isEmpty) {
      missingFields.add("Business Phone");
    }

    if (merchant.gstNumber.trim().isEmpty) {
      missingFields.add("GST Number");
    }

    if (merchant.city.trim().isEmpty) {
      missingFields.add("City");
    }

    if (merchant.state.trim().isEmpty) {
      missingFields.add("State");
    }

    if (merchant.country.trim().isEmpty) {
      missingFields.add("Country");
    }

    if (merchant.postalCode.trim().isEmpty) {
      missingFields.add("Postal Code");
    }

    return missingFields;
  }
}
