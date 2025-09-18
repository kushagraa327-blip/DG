import '../models/pagination_model.dart';

class SubscriptionResponse {
  Pagination? pagination;
  List<SubscriptionModel>? data;

  SubscriptionResponse({this.pagination, this.data});

  SubscriptionResponse.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
    if (json['data'] != null) {
      data = <SubscriptionModel>[];
      json['data'].forEach((v) {
        data!.add(SubscriptionModel.fromJson(v));
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

class SubscriptionModel {
  int? id;
  String? name;
  int? duration;
  String? durationUnit;
  num? price;
  String? description;
  String? status;
  String? createdAt;
  String? updatedAt;

  SubscriptionModel({this.id, this.name, this.duration, this.durationUnit, this.price, this.description, this.status, this.createdAt, this.updatedAt});

  SubscriptionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    duration = json['duration'];
    durationUnit = json['duration_unit'];
    price = json['price'];
    description = json['description'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['duration'] = duration;
    data['duration_unit'] = durationUnit;
    data['price'] = price;
    data['description'] = description;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
