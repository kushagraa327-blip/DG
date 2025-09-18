import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

/// Service for validating whether user input represents actual food items
class FoodValidationService {
  
  /// Validates if a text input represents a food item
  /// Returns a FoodValidationResult with validation status and details
  static Future<FoodValidationResult> validateFoodText(String input) async {
    try {
      print('🔍 Validating food text: "$input"');
      
      // Quick pre-validation for obviously non-food items
      if (_isObviouslyNonFood(input)) {
        return FoodValidationResult(
          isValid: false,
          errorMessage: 'Invalid input, please enter food items only',
          confidence: 0.95,
          detectedType: 'non-food-object',
        );
      }
      
      // Use AI to validate the input
      final aiValidation = await _validateWithAI(input);
      return aiValidation;
      
    } catch (e) {
      print('❌ Food validation error: $e');
      // On error, be conservative and allow the input but with low confidence
      return FoodValidationResult(
        isValid: true,
        errorMessage: null,
        confidence: 0.3,
        detectedType: 'unknown',
      );
    }
  }
  
  /// Validates if an image contains food items
  /// Returns a FoodValidationResult with validation status and details
  static Future<FoodValidationResult> validateFoodImage(File imageFile) async {
    try {
      print('🔍 Validating food image...');
      
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Use AI vision to validate the image
      final aiValidation = await _validateImageWithAI(base64Image);
      return aiValidation;
      
    } catch (e) {
      print('❌ Food image validation error: $e');
      return FoodValidationResult(
        isValid: false,
        errorMessage: 'Could not analyze image. Please try again or enter food manually.',
        confidence: 0.0,
        detectedType: 'error',
      );
    }
  }
  
  /// Quick pre-validation for obviously non-food items
  static bool _isObviouslyNonFood(String input) {
    final lowerInput = input.toLowerCase().trim();

    // First check if it's a known food item (including cultural foods)
    if (_isKnownFoodItem(lowerInput)) {
      return false; // It's a known food, so not non-food
    }

    // Common non-food objects
    final nonFoodKeywords = [
      'chair', 'table', 'desk', 'computer', 'phone', 'car', 'book', 'pen',
      'pencil', 'paper', 'wall', 'door', 'window', 'lamp', 'television',
      'tv', 'remote', 'keyboard', 'mouse', 'screen', 'monitor', 'clothes',
      'shirt', 'pants', 'shoes', 'hat', 'bag', 'wallet', 'keys', 'coin',
      'money', 'plastic', 'metal', 'wood', 'glass', 'stone', 'rock',
      'building', 'house', 'room', 'bathroom', 'bedroom', 'kitchen',
      'furniture', 'sofa', 'couch', 'bed', 'pillow', 'blanket', 'towel',
      'soap', 'shampoo', 'toothbrush', 'medicine', 'pill', 'drug',
      'cleaning', 'detergent', 'chemical', 'tool', 'hammer', 'screwdriver',
      'nail', 'screw', 'bolt', 'wire', 'cable', 'battery', 'charger',
      'electronic', 'device', 'gadget', 'toy', 'game', 'sport', 'ball',
      'equipment', 'instrument', 'musical', 'guitar', 'piano', 'drum',
    ];

    // Check if input contains obvious non-food keywords
    // But be more careful - only reject if it's clearly non-food
    for (final keyword in nonFoodKeywords) {
      if (lowerInput == keyword ||
          lowerInput.startsWith('$keyword ') ||
          lowerInput.endsWith(' $keyword') ||
          lowerInput.contains(' $keyword ')) {
        // Double-check it's not a food that happens to contain the keyword
        if (!_containsFoodContext(lowerInput)) {
          return true;
        }
      }
    }

    // Check for non-alphabetic patterns that might indicate non-food
    if (RegExp(r'^[0-9\s\-_+=!@#$%^&*()]+$').hasMatch(lowerInput)) {
      return true;
    }

    return false;
  }

  /// Check if input is a known food item (including cultural foods)
  static bool _isKnownFoodItem(String input) {
    final lowerInput = input.toLowerCase().trim();

    // Comprehensive food database including cultural foods
    final knownFoods = _getKnownFoodDatabase();

    // Direct match
    if (knownFoods.contains(lowerInput)) {
      return true;
    }

    // Check for partial matches with food terms
    for (final food in knownFoods) {
      if (lowerInput.contains(food) || food.contains(lowerInput)) {
        return true;
      }
    }

    return false;
  }

  /// Check if input contains food context (cooking terms, preparation methods, etc.)
  static bool _containsFoodContext(String input) {
    final foodContextTerms = [
      // Cooking methods
      'grilled', 'fried', 'baked', 'boiled', 'steamed', 'roasted', 'sauteed',
      'cooked', 'raw', 'fresh', 'dried', 'smoked', 'marinated', 'seasoned',

      // Food descriptors
      'spicy', 'sweet', 'sour', 'bitter', 'salty', 'hot', 'cold', 'warm',
      'organic', 'natural', 'homemade', 'traditional', 'authentic',

      // Meal contexts
      'breakfast', 'lunch', 'dinner', 'snack', 'meal', 'dish', 'recipe',
      'curry', 'soup', 'salad', 'sandwich', 'wrap', 'bowl',

      // Quantities and preparations
      'cup', 'bowl', 'plate', 'serving', 'portion', 'slice', 'piece',
      'chopped', 'diced', 'minced', 'grated', 'mashed', 'pureed',
    ];

    return foodContextTerms.any((term) => input.contains(term));
  }

  /// Get comprehensive known food database including cultural foods
  static Set<String> _getKnownFoodDatabase() {
    return {
      // Basic Western foods
      'apple', 'banana', 'orange', 'grape', 'strawberry', 'blueberry', 'mango',
      'chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna', 'turkey', 'lamb',
      'rice', 'bread', 'pasta', 'noodles', 'quinoa', 'oats', 'wheat', 'barley',
      'milk', 'cheese', 'yogurt', 'butter', 'cream', 'eggs',
      'tomato', 'potato', 'onion', 'garlic', 'carrot', 'broccoli', 'spinach',

      // Indian Staples
      'dal', 'daal', 'lentil', 'lentils', 'roti', 'chapati', 'naan', 'paratha',
      'biryani', 'pulao', 'pilaf', 'sambar', 'rasam', 'curry', 'sabzi',
      'chawal', 'bhat', 'anna', 'rice', 'basmati', 'jeera rice',

      // Indian Vegetables (English and Hindi names)
      'bhindi', 'okra', 'karela', 'bitter gourd', 'lauki', 'bottle gourd',
      'palak', 'spinach', 'aloo', 'potato', 'pyaz', 'onion', 'tamatar', 'tomato',
      'gajar', 'carrot', 'matar', 'peas', 'baingan', 'eggplant', 'brinjal',
      'gobi', 'cauliflower', 'shimla mirch', 'bell pepper', 'capsicum',
      'kaddu', 'pumpkin', 'tinda', 'round gourd', 'tori', 'ridge gourd',

      // Indian Spices and Ingredients
      'haldi', 'turmeric', 'jeera', 'cumin', 'dhania', 'coriander', 'ajwain',
      'garam masala', 'masala', 'hing', 'asafoetida', 'methi', 'fenugreek',
      'kala jeera', 'black cumin', 'rai', 'mustard seeds', 'til', 'sesame',
      'elaichi', 'cardamom', 'dalchini', 'cinnamon', 'laung', 'cloves',
      'kali mirch', 'black pepper', 'lal mirch', 'red chili', 'adrak', 'ginger',
      'lehsun', 'garlic', 'pudina', 'mint', 'tulsi', 'basil',

      // South Indian Foods
      'dosa', 'idli', 'vada', 'uttapam', 'upma', 'pongal', 'sambhar',
      'coconut chutney', 'chutney', 'appam', 'puttu', 'kozhukattai',
      'medu vada', 'rava dosa', 'masala dosa', 'plain dosa', 'set dosa',
      'idiyappam', 'sevai', 'lemon rice', 'curd rice', 'tamarind rice',

      // North Indian Foods
      'rajma', 'kidney beans', 'chole', 'chickpeas', 'chana', 'makki roti',
      'sarson saag', 'mustard greens', 'paneer', 'cottage cheese', 'ghee',
      'lassi', 'buttermilk', 'chaas', 'kulfi', 'rabri', 'kheer', 'payasam',
      'poha', 'flattened rice', 'upma', 'semolina', 'suji', 'rava',

      // Bengali Foods
      'machher jhol', 'fish curry', 'bhaat', 'rice', 'dal', 'shukto',
      'aloo posto', 'potato poppy', 'chingri malai curry', 'prawn curry',
      'mishti doi', 'sweet yogurt', 'rosogolla', 'rasgulla', 'sandesh',

      // Gujarati Foods
      'dhokla', 'khandvi', 'thepla', 'fafda', 'jalebi', 'undhiyu',
      'gujarati dal', 'kadhi', 'khichdi', 'handvo', 'muthiya',

      // Punjabi Foods
      'makki di roti', 'sarson da saag', 'butter chicken', 'tandoori',
      'kulcha', 'bhatura', 'chole bhature', 'amritsari kulcha',
      'punjabi kadhi', 'rajma chawal', 'dal makhani', 'paneer makhani',

      // Indian Sweets
      'gulab jamun', 'rasgulla', 'laddu', 'laddoo', 'halwa', 'kheer',
      'jalebi', 'imarti', 'kaju katli', 'barfi', 'peda', 'modak',
      'mysore pak', 'soan papdi', 'ras malai', 'kulfi', 'falooda',

      // Indian Breads
      'roti', 'chapati', 'naan', 'kulcha', 'paratha', 'puri', 'bhatura',
      'makki roti', 'bajra roti', 'jowar roti', 'missi roti', 'tandoori roti',

      // Indian Beverages
      'chai', 'tea', 'masala chai', 'lassi', 'buttermilk', 'chaas',
      'nimbu paani', 'lemonade', 'aam panna', 'mango drink', 'thandai',
      'filter coffee', 'south indian coffee', 'coconut water', 'nariyal paani',

      // Regional Specialties
      'vada pav', 'pav bhaji', 'misal pav', 'bhel puri', 'sev puri',
      'dahi puri', 'pani puri', 'golgappa', 'aloo tikki', 'samosa',
      'kachori', 'pakora', 'bhajiya', 'cutlet', 'sandwich',

      // Cooking ingredients and terms
      'tadka', 'tempering', 'baghaar', 'chonk', 'masala', 'gravy',
      'dry curry', 'wet curry', 'sabzi', 'vegetable', 'non-veg', 'veg',
      'pure veg', 'jain food', 'satvik', 'home cooked', 'ghar ka khana',

      // International foods commonly eaten in India
      'pizza', 'burger', 'sandwich', 'pasta', 'noodles', 'fried rice',
      'manchurian', 'chowmein', 'momos', 'spring roll', 'soup',

      // Common food combinations
      'dal chawal', 'dal rice', 'rajma chawal', 'chole chawal',
      'roti sabzi', 'chapati sabzi', 'paratha achar', 'dosa sambar',
      'idli sambar', 'poha jalebi', 'tea biscuit', 'chai nashta',

      // Jharkhand Cuisine
      'dhuska', 'dhushka', 'pittha', 'arsa', 'rugra', 'bamboo shoot curry',
      'bamboo shoot', 'jharkhand dal', 'tribal food', 'forest food',

      // Bihar Cuisine
      'litti chokha', 'litti', 'chokha', 'sattu paratha', 'sattu', 'khaja',
      'tilkut', 'chana ghugni', 'ghugni', 'bihari dal', 'bihari food',
      'malpua', 'thekua', 'anarsa', 'lai', 'kheer mohan',

      // Tamil Nadu Cuisine
      'paniyaram', 'kuska', 'kothu parotta', 'kothu', 'parotta', 'parotha',
      'chettinad chicken', 'chettinad', 'tamil food', 'tamil cuisine',
      'kuzhambu', 'kootu', 'poriyal', 'vadai', 'murukku', 'adhirasam',
      'payasam', 'kesari', 'rava kesari', 'semiya payasam',

      // Bengali Cuisine
      'machher bhat', 'fish rice', 'shorshe ilish', 'ilish', 'hilsa',
      'kosha mangsho', 'mangsho', 'mishti doi', 'rosogolla', 'rasgulla',
      'bengali food', 'bengali cuisine', 'macher jhol', 'fish curry',
      'aloo posto', 'posto', 'poppy seed', 'chingri malai curry',
      'prawn curry', 'bhapa ilish', 'steamed hilsa', 'sandesh',
      'roshmalai', 'ras malai', 'chomchom', 'langcha',

      // Assamese Cuisine
      'pitha', 'assamese pitha', 'til pitha', 'narikol pitha',
      'sunga saul', 'bamboo rice', 'khar', 'tenga', 'assamese food',
      'duck curry', 'ou tenga', 'elephant apple curry',

      // Northeastern Cuisine
      'momos', 'momo', 'thukpa', 'gundruk', 'kinema', 'churpi',
      'northeastern food', 'tibetan food', 'sikkim food', 'bhutanese food',
      'wonton', 'tingmo', 'sael roti', 'sel roti',

      // Gujarati Regional
      'dal dhokli', 'dhokli', 'gujarati dal', 'gujarati food',
      'sev tameta', 'ringan bharta', 'bhakri', 'rotli',
      'gujarati kadhi', 'mor kadi', 'aam ras', 'shrikhand',

      // Other Regional Specialties
      'misal pav', 'maharashtrian food', 'vada pav', 'bhel puri',
      'konkani food', 'goan food', 'fish curry', 'vindaloo',
      'xacuti', 'sorpotel', 'bebinca', 'dodol',
      'kerala food', 'malayali food', 'appam', 'stew', 'fish molee',
      'puttu', 'kadala curry', 'olan', 'avial', 'thoran',
      'andhra food', 'telugu food', 'hyderabadi food', 'biryani',
      'gongura', 'pesarattu', 'dosa', 'punugulu', 'bobbatlu',
      'karnataka food', 'kannada food', 'bisi bele bath', 'ragi mudde',
      'mysore pak', 'dharwad peda', 'holige', 'obbattu',
      'punjabi food', 'sarson da saag', 'makki di roti',
      'rajasthani food', 'dal baati churma', 'gatte ki sabzi',
      'ker sangri', 'bajre ki roti', 'laal maas',
      'kashmiri food', 'rogan josh', 'yakhni', 'kahwa', 'noon chai',
      'wazwan', 'tabak maaz', 'gustaba', 'rista',
    };
  }
  
  /// Use AI to validate if text represents food
  static Future<FoodValidationResult> _validateWithAI(String input) async {
    try {
      final prompt = '''You are a food validation expert with comprehensive knowledge of global cuisines, including Indian, Asian, African, Middle Eastern, and other cultural foods. Analyze the following input and determine if it represents a food item or ingredient that can be consumed by humans.

Input to analyze: "$input"

IMPORTANT: Recognize foods from ALL cultures and cuisines, including:
- Indian foods: dal, roti, chapati, naan, biryani, dosa, idli, sambar, rasam, etc.
- Regional Indian dishes: rajma chawal, chole, bhindi, karela, palak, etc.
- Spices and ingredients: turmeric (haldi), cumin (jeera), coriander (dhania), garam masala, etc.
- Traditional preparations: masala dosa, dal chawal, paneer makhani, etc.
- Cultural food combinations and regional names

Respond with ONLY a JSON object in this exact format:
{
  "isFood": true/false,
  "confidence": 0.0-1.0,
  "type": "food/beverage/ingredient/non-food/unclear",
  "reason": "brief explanation"
}

Rules:
- Return isFood: true for ANY actual food items, beverages, or edible ingredients from ANY culture
- Return isFood: false ONLY for non-food objects, furniture, electronics, etc.
- Be INCLUSIVE of cultural foods - when in doubt about cultural foods, lean towards accepting them
- Confidence should be 0.9+ for obvious cases, 0.7+ for cultural foods, 0.5-0.8 for unclear cases
- Type should be specific: food, beverage, ingredient, non-food, or unclear
- Keep reason brief (max 15 words)

Examples:
- "apple" → {"isFood": true, "confidence": 0.95, "type": "food", "reason": "common fruit"}
- "dal chawal" → {"isFood": true, "confidence": 0.9, "type": "food", "reason": "Indian lentil rice dish"}
- "masala dosa" → {"isFood": true, "confidence": 0.9, "type": "food", "reason": "South Indian crepe with spiced filling"}
- "wooden chair" → {"isFood": false, "confidence": 0.98, "type": "non-food", "reason": "furniture item"}
- "haldi" → {"isFood": true, "confidence": 0.85, "type": "ingredient", "reason": "turmeric spice"}''';

      final messages = [
        CoreMessage(role: 'system', content: prompt),
        CoreMessage(role: 'user', content: input),
      ];
      
      final response = await _callAIWithMessages(messages);
      return _parseValidationResponse(response);
      
    } catch (e) {
      print('❌ AI validation failed: $e');
      rethrow;
    }
  }
  
  /// Use AI vision to validate if image contains food
  static Future<FoodValidationResult> _validateImageWithAI(String base64Image) async {
    try {
      print('🔍 Using Gemini Vision for food image validation...');

      // Use Gemini for vision tasks since DeepSeek doesn't support images
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '''Analyze this image and determine if it contains any food items that can be consumed by humans. Be inclusive of ALL cultural cuisines including Indian, Asian, African, Middle Eastern, and other traditional foods.

IMPORTANT: Recognize foods from ALL cultures:
- Indian foods: dal, curry, roti, naan, dosa, idli, biryani, etc.
- Traditional dishes: thali, sambar, rasam, sabzi, etc.
- Regional preparations: masala dishes, traditional sweets, etc.
- Cultural cooking methods and presentations

Respond with ONLY a JSON object in this exact format:
{
  "isFood": true,
  "confidence": 0.9,
  "type": "food",
  "reason": "brief explanation",
  "foodItems": ["list", "of", "detected", "foods"]
}

Rules:
- Return isFood: true if the image contains ANY actual food items or beverages from ANY culture
- Return isFood: false ONLY if the image shows non-food objects, furniture, people, etc.
- Be INCLUSIVE of cultural foods - recognize traditional presentations and cooking styles
- Confidence should be 0.9+ for clear cases, 0.7+ for cultural foods, 0.5-0.8 for unclear cases
- List specific food items detected in foodItems array (use both common and cultural names)
- Keep reason brief (max 20 words)
- BIAS TOWARDS FOOD: If unsure, assume it's food rather than non-food'''
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 1024,
        }
      };

      final url = '${AIConfig.gemini['baseUrl']}/${AIConfig.gemini['model']}:generateContent?key=${AIConfig.gemini['apiKey']}';
      print('🌐 Gemini Vision API URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('🔍 Gemini Vision Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📄 Gemini Vision Response: ${jsonEncode(responseData)}');

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {

          final content = responseData['candidates'][0]['content']['parts'][0]['text'];
          print('✅ Gemini Vision Content: $content');
          return _parseValidationResponse(content);
        }
      }

      print('❌ Gemini Vision API failed with status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      throw Exception('Failed to get response from Gemini Vision API');

    } catch (e) {
      print('❌ AI image validation failed: $e');
      // Return a more permissive result if AI fails
      return FoodValidationResult(
        isValid: true, // Be permissive when AI fails
        errorMessage: null,
        confidence: 0.5,
        detectedType: 'food',
        reason: 'AI validation unavailable, allowing image',
        detectedFoods: ['unknown food item'],
      );
    }
  }
  
  /// Parse AI response into FoodValidationResult
  static FoodValidationResult _parseValidationResponse(String response) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('No JSON found in response');
      }
      
      final jsonStr = jsonMatch.group(0)!;
      final data = jsonDecode(jsonStr);
      
      final isValid = data['isFood'] == true;
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.5;
      final type = data['type']?.toString() ?? 'unknown';
      final reason = data['reason']?.toString() ?? 'No reason provided';
      
      return FoodValidationResult(
        isValid: isValid,
        errorMessage: isValid ? null : 'Invalid input, please enter food items only',
        confidence: confidence,
        detectedType: type,
        reason: reason,
        detectedFoods: data['foodItems'] != null 
            ? List<String>.from(data['foodItems']) 
            : null,
      );
      
    } catch (e) {
      print('❌ Failed to parse validation response: $e');
      // Return conservative result on parsing error
      return FoodValidationResult(
        isValid: false,
        errorMessage: 'Could not validate input. Please try again.',
        confidence: 0.0,
        detectedType: 'error',
      );
    }
  }
  
  /// Call AI service with messages (reuse from ai_service.dart)
  static Future<String> _callAIWithMessages(List<CoreMessage> messages) async {
    // Use the existing AI service infrastructure
    return await _callAIWithMessagesInternal(messages);
  }
  
  /// Internal AI call method
  static Future<String> _callAIWithMessagesInternal(List<CoreMessage> messages) async {
    if (AIConfig.openrouter['enabled'] && AIConfig.openrouter['apiKey']?.toString().isNotEmpty == true) {
      try {
        return await _callOpenRouter(messages);
      } catch (e) {
        print('❌ OpenRouter validation call failed: $e');
      }
    }
    
    if (AIConfig.gemini['enabled'] && AIConfig.gemini['apiKey']?.toString().isNotEmpty == true) {
      try {
        return await _callGemini(messages);
      } catch (e) {
        print('❌ Gemini validation call failed: $e');
      }
    }
    
    throw Exception('No AI service available for validation');
  }
  
  /// Call OpenRouter API for validation
  static Future<String> _callOpenRouter(List<CoreMessage> messages) async {
    final formattedMessages = messages.map((m) => {
      'role': m.role,
      'content': m.content.toString(),
    }).toList();

    final requestBody = {
      'model': 'deepseek/deepseek-chat-v3:free', // Use DeepSeek V3 0324 (free)
      'messages': formattedMessages,
      'max_tokens': 1024,
      'temperature': 0.1,
    };

    final response = await http.post(
      Uri.parse(AIConfig.openrouter['url']),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AIConfig.openrouter['apiKey']}',
        'HTTP-Referer': AIConfig.openrouter['siteUrl'],
        'X-Title': AIConfig.openrouter['siteName'],
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['choices'] != null &&
          responseData['choices'].isNotEmpty &&
          responseData['choices'][0]['message'] != null &&
          responseData['choices'][0]['message']['content'] != null) {
        return responseData['choices'][0]['message']['content'];
      }
    }
    
    throw Exception('OpenRouter API call failed');
  }
  
  /// Call Gemini API for validation
  static Future<String> _callGemini(List<CoreMessage> messages) async {
    final combinedContent = messages.map((m) => m.content.toString()).join('\n\n');
    
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': combinedContent}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 1024,
      }
    };

    final url = '${AIConfig.gemini['baseUrl']}/${AIConfig.gemini['model']}:generateContent?key=${AIConfig.gemini['apiKey']}';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['candidates'] != null &&
          responseData['candidates'].isNotEmpty &&
          responseData['candidates'][0]['content'] != null &&
          responseData['candidates'][0]['content']['parts'] != null &&
          responseData['candidates'][0]['content']['parts'].isNotEmpty) {
        return responseData['candidates'][0]['content']['parts'][0]['text'];
      }
    }
    
    throw Exception('Gemini API call failed');
  }
}

/// Result of food validation
class FoodValidationResult {
  final bool isValid;
  final String? errorMessage;
  final double confidence; // 0.0 to 1.0
  final String detectedType; // food, beverage, ingredient, non-food, unclear, error
  final String? reason;
  final List<String>? detectedFoods; // For image validation
  
  FoodValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.confidence,
    required this.detectedType,
    this.reason,
    this.detectedFoods,
  });
  
  @override
  String toString() {
    return 'FoodValidationResult(isValid: $isValid, confidence: $confidence, type: $detectedType, reason: $reason)';
  }
}
