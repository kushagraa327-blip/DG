# 🤖 IRA AI Service Setup Guide

## 🚀 Quick Setup (2 Minutes)

### Current Status: ✅ Working with Smart Mock Responses
Your IRA is currently providing intelligent fitness responses using mock data. To enable full AI capabilities, follow the steps below.

### 🔧 Enable Full AI (Optional - Free)

**Step 1**: Get Free API Key
1. Go to https://openrouter.ai/
2. Sign up (free account)
3. Go to "Keys" section
4. Create a new API key
5. Copy the key (starts with `sk-or-v1-`)

**Step 2**: Add API Key
1. Open `lib/services/ai_service.dart`
2. Find line ~65 (AIConfig class)
3. Update these two lines:

```dart
'enabled': true, // ← Change false to true
'apiKey': 'sk-or-v1-your-key-here', // ← Paste your API key here
```

**Step 3**: Test Your Setup
1. Hot reload the app
2. Click IRA button
3. Send "Hello" message
4. You should see AI-powered responses!

## 📱 Current Features (Working Now!)

### ✅ Smart Mock Responses
- **Nutrition Questions**: "How many calories in potato?" → Detailed nutrition info
- **Greetings**: "Hi" → Personalized welcome from IRA
- **Name Questions**: "What's your name?" → IRA introduces herself
- **Workout Help**: Exercise and fitness guidance
- **Motivation**: Encouraging fitness messages

### 🤖 With AI Enabled (After Setup)
- **Personalized Advice**: Based on your profile (age, weight, goals)
- **Dynamic Responses**: Contextual answers to any fitness question
- **Meal Planning**: Custom meal plans based on your preferences
- **Health Insights**: BMI calculations and health recommendations

## Available Models

### Free OpenRouter Models:
- `deepseek/deepseek-chat-v3-0324:free` (Default - Recommended)
- `google/gemini-2.0-flash-exp:free`
- `meta-llama/llama-3.1-8b-instruct:free`
- `mistralai/mistral-7b-instruct:free`
- `microsoft/phi-3-mini-128k-instruct:free`

### Premium Models:
- `deepseek/deepseek-chat` (Latest DeepSeek V3)
- `openai/gpt-4o-mini`
- `anthropic/claude-3.5-sonnet`
- `google/gemini-2.5-flash`

## Fallback System

The AI service uses this priority order:
1. **OpenRouter** (if enabled and API key provided)
2. **OpenAI** (if enabled and API key provided)  
3. **Primary API** (currently disabled)
4. **Mock Responses** (always available as final fallback)

## Features

✅ **Fixed Bottom Navigation Issue** - Text input no longer hides behind system navigation
✅ **Smart Fallback System** - Always works even without API keys
✅ **Personalized Responses** - Uses user profile data for better answers
✅ **Fitness-Focused** - Specialized for health and fitness queries
✅ **Easy Configuration** - Just add your API key and set enabled: true

## Troubleshooting

### If AI responses aren't working:
1. Check console logs for error messages
2. Verify API key is correct and starts with proper prefix
3. Ensure `enabled: true` is set
4. Test with mock responses first (always available)

### Console Log Messages:
- ✅ "OpenRouter AI response generated successfully" = Working!
- ❌ "OpenRouter Authentication Failed" = Check API key
- ℹ️ "Using mock AI response" = Fallback mode (no API key)

## Support

- OpenRouter: https://openrouter.ai/docs
- OpenAI: https://platform.openai.com/docs
- Mock responses work without any setup
