class Deal {
  final String dealId;
  final String buyerWallet;
  final String? sellerWallet;
  final String status;
  final String? datasetId;
  final String solanaTxHash;
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
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String)
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'deal_meta': dealMeta?.toJson(),
    };
  }
}

class DealMeta {
  final String currency;
  final String dataType;
  final String price;
  final String requestDescription;

  DealMeta({
    required this.currency,
    required this.dataType,
    required this.price,
    required this.requestDescription,
  });

  factory DealMeta.fromJson(Map<String, dynamic> json) {
    return DealMeta(
      currency: json['currency'] as String,
      dataType: json['data_type'] as String,
      price: json['price'] as String,
      requestDescription: json['request_description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'data_type': dataType,
      'price': price,
      'request_description': requestDescription,
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
