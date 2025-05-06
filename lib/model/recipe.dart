class Recipe {
  final String title;
  final int numberOfPeople;
  final int duration; // Minutes
  final String imageUrl;
  List<String> steps;
  List<String> ingredients;

   Recipe({
    required this.title,
    required this.duration,
     required this.numberOfPeople,
    required this.imageUrl,
    required this.steps,
     required this.ingredients
  });
}