// models/subscription_plan.dart
class SubscriptionPlan {
  final String name;
  final double price;
  final String duration;
  final String description;
  final bool isPopular;

  SubscriptionPlan({
    required this.name,
    required this.price,
    required this.duration,
    required this.description,
    required this.isPopular,
  });
}