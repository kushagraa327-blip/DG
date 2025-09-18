import '../models/pagination_model.dart';

class SubscriptionPlanResponse {
  Pagination? pagination;
  List<SubscriptionPlan>? data;

  SubscriptionPlanResponse({this.pagination, this.data});

  SubscriptionPlanResponse.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
    if (json['data'] != null) {
      data = <SubscriptionPlan>[];
      json['data'].forEach((v) {
        data!.add(SubscriptionPlan.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (pagination != null) {
      data['pagination'] = pagination!.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SubscriptionPlan {
  int? id;
  int? userId;
  String? userName;
  int? packageId;
  String? packageName;
  num? totalAmount;
  String? paymentType;
  String? txnId;
  TransactionDetail? transactionDetail;
  String? paymentStatus;
  String? status;
  PackageData? packageData;
  String? subscriptionStartDate;
  String? subscriptionEndDate;
  String? createdAt;
  String? updatedAt;

  SubscriptionPlan(
      {this.id,
      this.userId,
      this.userName,
      this.packageId,
      this.packageName,
      this.totalAmount,
      this.paymentType,
      this.txnId,
      this.transactionDetail,
      this.paymentStatus,
      this.status,
      this.packageData,
      this.subscriptionStartDate,
      this.subscriptionEndDate,
      this.createdAt,
      this.updatedAt});

  SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    userName = json['user_name'];
    packageId = json['package_id'];
    packageName = json['package_name'];
    totalAmount = json['total_amount'];
    paymentType = json['payment_type'];
    txnId = json['txn_id'];
    transactionDetail = json['transaction_detail'] != null
        ? TransactionDetail.fromJson(json['transaction_detail'])
        : null;
    paymentStatus = json['payment_status'];
    status = json['status'];
    packageData = json['package_data'] != null ? PackageData.fromJson(json['package_data']) : null;
    subscriptionStartDate = json['subscription_start_date'];
    subscriptionEndDate = json['subscription_end_date'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['user_name'] = userName;
    data['package_id'] = packageId;
    data['package_name'] = packageName;
    data['total_amount'] = totalAmount;
    data['payment_type'] = paymentType;
    data['txn_id'] = txnId;
    if (transactionDetail != null) {
      data['transaction_detail'] = transactionDetail!.toJson();
    }
    data['payment_status'] = paymentStatus;
    data['status'] = status;
    if (packageData != null) {
      data['package_data'] = packageData!.toJson();
    }
    data['subscription_start_date'] = subscriptionStartDate;
    data['subscription_end_date'] = subscriptionEndDate;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class PackageData {
  int? id;
  String? name;
  num? price;
  String? status;
  int? duration;
  String? createdAt;
  String? updatedAt;
  String? description;
  String? durationUnit;

  PackageData({this.id, this.name, this.price, this.status, this.duration, this.createdAt, this.updatedAt, this.description, this.durationUnit});

  PackageData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    price = json['price'];
    status = json['status'];
    duration = json['duration'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    description = json['description'];
    durationUnit = json['duration_unit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['price'] = price;
    data['status'] = status;
    data['duration'] = duration;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['description'] = description;
    data['duration_unit'] = durationUnit;
    return data;
  }
}

class TransactionDetail {
  String? name;
  int? addedBy;

  TransactionDetail({this.name, this.addedBy});

  TransactionDetail.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    addedBy = json['added_by'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['added_by'] = addedBy;
    return data;
  }
}