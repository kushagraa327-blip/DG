import '../models/pagination_model.dart';

class GraphResponse {
  Pagination? pagination;
  List<GraphModel>? data;

  GraphResponse({this.pagination, this.data});

  GraphResponse.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
    if (json['data'] != null) {
      data = <GraphModel>[];
      json['data'].forEach((v) {
        data!.add(GraphModel.fromJson(v));
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

class GraphModel {
  int? id;
  String? value;
  String? type;
  String? date;
  String? unit;
  String? createdAt;
  String? updatedAt;

  GraphModel(
      {this.id,
        this.value,
        this.type,
        this.date,
        this.unit,
        this.createdAt,
        this.updatedAt});

  GraphModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    value = json['value'];
    type = json['type'];
    date = json['date'];
    unit = json['unit'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['value'] = value;
    data['type'] = type;
    data['date'] = date;
    data['unit'] = unit;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
