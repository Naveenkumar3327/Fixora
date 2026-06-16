import 'dart:math';

class GoogleReview {
  final String authorName;
  final double rating;
  final String text;
  final String relativeTimeDescription;

  GoogleReview({
    required this.authorName,
    required this.rating,
    required this.text,
    required this.relativeTimeDescription,
  });
}

class MLSearchResult {
  final String classifiedCategory;
  final double confidence;
  final String explanation;
  final List<GoogleReview> mockGoogleReviews;

  MLSearchResult({
    required this.classifiedCategory,
    required this.confidence,
    required this.explanation,
    required this.mockGoogleReviews,
  });
}

class WorkIntentClassifier {
  // Simple NLP Classifier acting as an in-app Machine Learning model for service categories.
  static final Map<String, List<String>> _categoryKeywords = {
    "Electrician": [
      "short-circuit", "wire", "fuse", "fan", "light", "current", "shock", "switch", "spark", "electric", "board",
      "power cut", "voltage", "bulb", "mcb", "inverter", "plug", "socket", "wiring", "sparking"
    ],
    "Plumber": [
      "leak", "tap", "sink", "pipe", "toilet", "water", "drain", "basin", "clog", "shower", "flush", "plumb", "faucet",
      "pipeline", "overflow", "sewer", "blockage", "bathroom leak", "kitchen leak"
    ],
    "Mechanic": [
      "car", "bike", "engine", "brake", "repair", "oil", "puncture", "wheel", "gear", "vehicle", "mechanic", "clutch",
      "accelerator", "scooter", "tyre", "radiator", "breakdown"
    ],
    "Carpenter": [
      "wooden", "chair", "table", "door", "window", "bed", "wood", "carpenter", "furniture", "cupboard", "cabinet",
      "sofa", "latch", "lock repair", "hinge", "drawer"
    ],
    "AC Repair": [
      "ac", "cooling", "filter", "compressor", "air conditioner", "gas leak", "chill", "remote", "ac repair", "heating",
      "condenser", "ventilation", "leakage"
    ],
    "Painter": [
      "wall", "paint", "color", "brush", "coating", "painter", "wallpaper", "distemper", "texture", "whitewash",
      "ceiling", "peeling"
    ],
    "Cleaner": [
      "dust", "clean", "wash", "vacuum", "sweep", "mop", "cleaner", "hygiene", "sofa dry clean", "bathroom cleaning",
      "kitchen cleaning", "garbage"
    ],
    "RO Service": [
      "water filter", "ro", "purifier", "membrane", "taste", "tds", "cartridge", "leak", "filter change", "ro repair",
      "filter service"
    ],
    "Appliance Repair": [
      "fridge", "refrigerator", "washing machine", "microwave", "oven", "tv", "kitchen", "appliance", "geyser", 
      "heater", "dryer", "induction", "chimney"
    ],
    "Home Maintenance": [
      "drill", "mount", "repair", "fix", "tile", "plaster", "lock", "home maintenance", "handyman", "renovation",
      "grouting", "shelves"
    ]
  };

  static MLSearchResult classify(String query) {
    final cleanQuery = query.toLowerCase();
    
    // Feature extraction: tokenization and word analysis
    final words = cleanQuery.split(RegExp(r'\s+'));
    
    String bestCategory = "Home Maintenance"; // Fallback default
    double bestScore = 0.0;
    
    _categoryKeywords.forEach((category, keywords) {
      double score = 0.0;
      for (var word in words) {
        for (var keyword in keywords) {
          if (word == keyword) {
            score += 2.0; // High weight for exact match
          } else if (word.contains(keyword) || keyword.contains(word)) {
            if (word.length > 3 && keyword.length > 3) {
              score += 0.8; // Partial overlap
            }
          }
        }
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestCategory = category;
      }
    });

    // Compute confidence rating dynamically
    double confidence = 0.0;
    if (bestScore > 0) {
      confidence = min(0.98, 0.4 + (bestScore * 0.12));
    } else {
      confidence = 0.15; // default fallback
    }

    String explanation = "Could not identify category clearly. Displaying general home maintenance specialists.";
    if (bestScore > 0.0) {
      explanation = "Detected issue related to $bestCategory. Matching nearest specialists.";
    }

    // Generate custom Google Reviews based on category
    List<GoogleReview> reviews = _generateGoogleReviews(bestCategory);

    return MLSearchResult(
      classifiedCategory: bestCategory,
      confidence: confidence,
      explanation: explanation,
      mockGoogleReviews: reviews,
    );
  }

  static List<GoogleReview> _generateGoogleReviews(String category) {
    final List<Map<String, String>> templates = [
      {
        "author": "Rahul Gupta",
        "text": "Very quick service. Solved my issue in no time. Recommended!",
        "rating": "5.0"
      },
      {
        "author": "Sneha Sharma",
        "text": "The worker arrived on time, was extremely polite, and cleaned up after completing the job.",
        "rating": "4.5"
      },
      {
        "author": "Vikram Singh",
        "text": "Reasonable pricing and highly professional work. Will book again.",
        "rating": "5.0"
      },
      {
        "author": "Neha Malhotra",
        "text": "Good experience. They explained the issue clearly and fixed it standardly.",
        "rating": "4.0"
      }
    ];

    String getServiceText(String cat, int index) {
      switch (cat) {
        case "Plumber":
          return [
            "Fixed my leaking tap in the bathroom standardly. Highly professional!",
            "Cleared a stubborn kitchen drain clog. Fast and neat work.",
            "Replaced the flush system in our toilet. Clean and prompt service.",
            "Standard pressure check done for the overhead pipes."
          ][index];
        case "Electrician":
          return [
            "Diagnosed and resolved the short circuit issue in our master bedroom.",
            "Fitted the new ceiling fans and light sockets standardly.",
            "Fixed the sparking switch board quickly. Appreciate the safety precautions taken.",
            "Installed our home inverter setup seamlessly."
          ][index];
        case "AC Repair":
          return [
            "AC is cooling perfectly now. Excellent service and filter cleaning.",
            "Recharged the gas in my split AC. Fair pricing compared to others.",
            "Resolved the water leaking from my indoor unit.",
            "Cleaned the outdoor condenser coil. Very professional AC service."
          ][index];
        case "Carpenter":
          return [
            "Beautiful repairs to our wooden table and drawer slides.",
            "Fixed the sagging hinges of our main wooden door.",
            "Built standard custom shelves inside the kitchen cabinet.",
            "Polished and strengthened the dining room chairs."
          ][index];
        default:
          return templates[index]["text"]!;
      }
    }

    return List.generate(templates.length, (index) {
      return GoogleReview(
        authorName: templates[index]["author"]!,
        rating: double.parse(templates[index]["rating"]!),
        text: getServiceText(category, index),
        relativeTimeDescription: "${index + 1} week(s) ago",
      );
    });
  }
}
