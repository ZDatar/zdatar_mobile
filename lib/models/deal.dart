class Deal {
  final String dealId;
  final String buyerWallet;
  final String? sellerWallet;
  final String status;
  final String? datasetId;
  final String solanaTxHash;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final DealMeta? dealMeta;

  Deal({
    required this.dealId,
    required this.buyerWallet,
    this.sellerWallet,
    required this.status,
    this.datasetId,
    required this.solanaTxHash,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.dealMeta,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      dealId: json['deal_id'] as String,
      buyerWallet: json['buyer_wallet'] as String,
      sellerWallet: json['seller_wallet'] as String?,
      status: json['status'] as String,
      datasetId: json['dataset_id'] as String?,
      solanaTxHash: json['solana_tx_hash'] as String,
      icon: json['icon'] as String? ?? '📊',
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String).toUtc()
          : null,
      dealMeta: json['deal_meta'] != null
          ? DealMeta.fromJson(json['deal_meta'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deal_id': dealId,
      'buyer_wallet': buyerWallet,
      'seller_wallet': sellerWallet,
      'status': status,
      'dataset_id': datasetId,
      'solana_tx_hash': solanaTxHash,
      'icon': icon,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'deal_meta': dealMeta?.toJson(),
    };
  }
}

class DealMeta {
  final String currency;
  final String? dataType;
  final String dataCategory;
  final List<String> dataSubcategories;
  final List<String> dataFieldsRequired;
  final String price;
  final String requestDescription;
  final String buyerWallet;

  DealMeta({
    required this.currency,
    this.dataType,
    required this.dataCategory,
    required this.dataSubcategories,
    required this.dataFieldsRequired,
    required this.price,
    required this.requestDescription,
    required this.buyerWallet,
  });

  factory DealMeta.fromJson(Map<String, dynamic> json) {
    return DealMeta(
      currency: json['currency'] as String,
      dataType: json['data_type'] as String?,
      dataCategory: json['data_category'] as String,
      dataSubcategories: (json['subcategories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      dataFieldsRequired: (json['data_fields_required'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      price: json['price'] as String,
      requestDescription: json['request_description'] as String,
      buyerWallet: json['buyer_wallet'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      if (dataType != null) 'data_type': dataType,
      'data_category': dataCategory,
      'data_subcategories': dataSubcategories,
      'data_fields_required': dataFieldsRequired,
      'price': price,
      'request_description': requestDescription,
      'buyer_wallet': buyerWallet,
    };
  }
}

class DealsResponse {
  final List<Deal> deals;
  final int total;

  DealsResponse({
    required this.deals,
    required this.total,
  });

  factory DealsResponse.fromJson(Map<String, dynamic> json) {
    return DealsResponse(
      deals: (json['deals'] as List)
          .map((deal) => Deal.fromJson(deal as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}
