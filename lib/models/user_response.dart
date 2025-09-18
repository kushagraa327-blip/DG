class UserResponse {
  Data? data;
  SubscriptionDetail? subscriptionDetail;

  UserResponse({this.data, this.subscriptionDetail});

  UserResponse.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    subscriptionDetail = json['subscription_detail'] != null
        ? SubscriptionDetail.fromJson(json['subscription_detail'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    if (subscriptionDetail != null) {
      data['subscription_detail'] = subscriptionDetail!.toJson();
    }
    return data;
  }
}

class Data {
  int? id;
  String? firstName;
  String? lastName;
  String? displayName;
  String? email;
  String? username;
  String? gender;
  String? goal;  // ✅ Added goal field
  String? status;
  String? userType;
  String? phoneNumber;
  String? playerId;
  String? profileImage;
  String? loginType;
  String? createdAt;
  String? updatedAt;
  UserProfile? userProfile;
  int? isSubscribe;

  Data(
      {this.id,
        this.firstName,
        this.lastName,
        this.displayName,
        this.email,
        this.username,
        this.gender,
        this.goal,  // ✅ Added goal parameter
        this.status,
        this.userType,
        this.phoneNumber,
        this.playerId,
        this.profileImage,
        this.loginType,
        this.createdAt,
        this.updatedAt,
        this.userProfile,
        this.isSubscribe});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    displayName = json['display_name'];
    email = json['email'];
    username = json['username'];
    gender = json['gender'];
    goal = json['goal'];  // ✅ Added goal parsing
    status = json['status'];
    userType = json['user_type'];
    phoneNumber = json['phone_number'];
    playerId = json['player_id'];
    profileImage = json['profile_image'];
    loginType = json['login_type'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    userProfile = json['user_profile'] != null
        ? UserProfile.fromJson(json['user_profile'])
        : null;
    isSubscribe = json['is_subscribe'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['display_name'] = displayName;
    data['email'] = email;
    data['username'] = username;
    data['gender'] = gender;
    data['goal'] = goal;  // ✅ Added goal to JSON
    data['status'] = status;
    data['user_type'] = userType;
    data['phone_number'] = phoneNumber;
    data['player_id'] = playerId;
    data['profile_image'] = profileImage;
    data['login_type'] = loginType;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (userProfile != null) {
      data['user_profile'] = userProfile!.toJson();
    }
    data['is_subscribe'] = isSubscribe;
    return data;
  }
}

class UserProfile {
  int? id;
  String? age;
  String? weight;
  String? weightUnit;
  String? height;
  String? heightUnit;
  String? address;
  String? goal;
  int? userId;
  String? createdAt;
  String? updatedAt;

  UserProfile(
      {this.id,
        this.age,
        this.weight,
        this.weightUnit,
        this.height,
        this.heightUnit,
        this.address,
        this.goal,
        this.userId,
        this.createdAt,
        this.updatedAt});

  UserProfile.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    age = json['age'];
    weight = json['weight'];
    weightUnit = json['weight_unit'];
    height = json['height'];
    heightUnit = json['height_unit'];
    address = json['address'];
    goal = json['goal'];
    userId = json['user_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['age'] = age;
    data['weight'] = weight;
    data['weight_unit'] = weightUnit;
    data['height'] = height;
    data['height_unit'] = heightUnit;
    data['address'] = address;
    data['goal'] = goal;
    data['user_id'] = userId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class SubscriptionDetail {
  int? isSubscribe;
  SubscriptionPlan? subscriptionPlan;

  SubscriptionDetail({this.isSubscribe, this.subscriptionPlan});

  SubscriptionDetail.fromJson(Map<String, dynamic> json) {
    isSubscribe = json['is_subscribe'];
    subscriptionPlan = json['subscription_plan'] != null
        ? SubscriptionPlan.fromJson(json['subscription_plan'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_subscribe'] = isSubscribe;
    if (subscriptionPlan != null) {
      data['subscription_plan'] = subscriptionPlan!.toJson();
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
    packageData = json['package_data'] != null
        ? PackageData.fromJson(json['package_data'])
        : null;
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

  PackageData(
      {this.id,
        this.name,
        this.price,
        this.status,
        this.duration,
        this.createdAt,
        this.updatedAt,
        this.description,
        this.durationUnit});

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