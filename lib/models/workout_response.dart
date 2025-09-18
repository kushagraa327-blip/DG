import 'pagination_model.dart';
import 'workout_detail_response.dart';

class WorkoutResponse {
  Pagination? pagination;
  List<WorkoutDetailModel>? data;

  WorkoutResponse({this.pagination, this.data});

  WorkoutResponse.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
    if (json['data'] != null) {
      data = <WorkoutDetailModel>[];
      json['data'].forEach((v) {
        data!.add(WorkoutDetailModel.fromJson(v));
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
