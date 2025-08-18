# PocketBase Setup Guide for Social Media App

## 📋 Prerequisites

1. **PocketBase Server**: Download from [pocketbase.io](https://pocketbase.io/)
2. **Flutter App**: Already configured with PocketBase integration

## 🚀 Setup Steps

### 1. Download PocketBase

```bash
# For macOS
wget https://github.com/pocketbase/pocketbase/releases/download/v0.20.0/pocketbase_0.20.0_darwin_amd64.zip
unzip pocketbase_0.20.0_darwin_amd64.zip

# For Windows
# Download from https://github.com/pocketbase/pocketbase/releases
```

### 2. Start PocketBase Server

```bash
./pocketbase serve
```

Server will start at: `http://127.0.0.1:8090`

### 3. Create Collections

#### Users Collection
```json
{
  "name": "users",
  "type": "auth",
  "schema": [
    {
      "name": "name",
      "type": "text",
      "required": true
    },
    {
      "name": "username",
      "type": "text",
      "required": false,
      "unique": true
    },
    {
      "name": "bio",
      "type": "text",
      "required": false
    },
    {
      "name": "followersCount",
      "type": "number",
      "required": false,
      "default": 0
    },
    {
      "name": "followingCount",
      "type": "number",
      "required": false,
      "default": 0
    },
    {
      "name": "postsCount",
      "type": "number",
      "required": false,
      "default": 0
    },
    {
      "name": "verified",
      "type": "bool",
      "required": false,
      "default": false
    }
  ]
}
```

#### Posts Collection
```json
{
  "name": "posts",
  "type": "base",
  "schema": [
    {
      "name": "content",
      "type": "text",
      "required": true
    },
    {
      "name": "images",
      "type": "json",
      "required": false
    },
    {
      "name": "likesCount",
      "type": "number",
      "required": false,
      "default": 0
    },
    {
      "name": "commentsCount",
      "type": "number",
      "required": false,
      "default": 0
    },
    {
      "name": "sharesCount",
      "type": "number",
      "required": false,
      "default": 0
    },
    {
      "name": "author",
      "type": "relation",
      "required": true,
      "options": {
        "collectionId": "users",
        "cascadeDelete": true
      }
    }
  ]
}
```

#### Comments Collection
```json
{
  "name": "comments",
  "type": "base",
  "schema": [
    {
      "name": "content",
      "type": "text",
      "required": true
    },
    {
      "name": "post",
      "type": "relation",
      "required": true,
      "options": {
        "collectionId": "posts",
        "cascadeDelete": true
      }
    },
    {
      "name": "author",
      "type": "relation",
      "required": true,
      "options": {
        "collectionId": "users",
        "cascadeDelete": true
      }
    }
  ]
}
```

### 4. Configure Authentication

1. Go to `http://127.0.0.1:8090/_/`
2. Create admin account
3. Go to Settings > Auth providers
4. Enable email/password authentication

### 5. Set Collection Rules

#### Users Collection Rules
```javascript
// List rule
@request.auth.id != ""

// View rule
@request.auth.id != ""

// Create rule
@request.auth.id = ""

// Update rule
@request.auth.id = id

// Delete rule
@request.auth.id = id
```

#### Posts Collection Rules
```javascript
// List rule
true

// View rule
true

// Create rule
@request.auth.id != ""

// Update rule
@request.auth.id = author

// Delete rule
@request.auth.id = author
```

#### Comments Collection Rules
```javascript
// List rule
true

// View rule
true

// Create rule
@request.auth.id != ""

// Update rule
@request.auth.id = author

// Delete rule
@request.auth.id = author
```

## 🔧 Flutter App Configuration

The Flutter app is already configured to work with PocketBase:

- **Service**: `lib/services/pocketbase_service.dart`
- **URL**: `http://127.0.0.1:8090`
- **Collections**: users, posts, comments

## 🧪 Testing

1. Start PocketBase server
2. Run Flutter app: `flutter run`
3. Register a new account
4. Create posts and test features

## 📱 Features Implemented

- ✅ User registration/login (no email verification required)
- ✅ Create posts
- ✅ View posts feed
- ✅ Like posts
- ✅ Add comments
- ✅ User profiles
- ✅ Real-time data sync

## 🚨 Troubleshooting

### Common Issues

1. **Connection Error**: Make sure PocketBase server is running
2. **Authentication Error**: Check collection rules
3. **CORS Error**: Add Flutter app to allowed origins in PocketBase settings

### Debug Mode

Enable debug logging in PocketBase:
```bash
./pocketbase serve --debug
```

## 📚 Next Steps

1. **File Upload**: Implement image upload functionality
2. **Real-time**: Add WebSocket support for live updates
3. **Push Notifications**: Integrate FCM
4. **Offline Support**: Add local storage
5. **Search**: Implement full-text search
6. **Follow System**: Add user following functionality

## 🔗 Resources

- [PocketBase Documentation](https://pocketbase.io/docs/)
- [Flutter PocketBase Package](https://pub.dev/packages/pocketbase)
- [API Reference](https://pocketbase.io/docs/api-records/) 